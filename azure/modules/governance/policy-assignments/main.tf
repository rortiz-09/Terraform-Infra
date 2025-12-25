# ==================================================================================================
# MÓDULO: AZURE POLICY ASSIGNMENTS - GUARDRAILS
# ==================================================================================================
# Autor: Ronny Ortiz
# Propósito: Enforcement de políticas de compliance en Azure
# WAF Pillar: Security - Policy-as-code
# ==================================================================================================

variable "subscription_id" {
  description = "Subscription ID donde aplicar policies"
  type        = string
  default     = null
}

variable "management_group_id" {
  description = "Management Group ID (más amplio que subscription)"
  type        = string
  default     = null
}

variable "enforcement_mode" {
  description = "Modo de enforcement: Default (deny) o DoNotEnforce (audit only)"
  type        = string
  default     = "Default"

  validation {
    condition     = contains(["Default", "DoNotEnforce"], var.enforcement_mode)
    error_message = "Enforcement mode debe ser 'Default' o 'DoNotEnforce'."
  }
}

# --------------------------------------------------------------------------------------------------
# DATA SOURCES
# --------------------------------------------------------------------------------------------------
data "azurerm_subscription" "current" {
  count = var.subscription_id == null ? 1 : 0
}

locals {
  scope = var.management_group_id != null ? var.management_group_id : (
    var.subscription_id != null ? "/subscriptions/${var.subscription_id}" : data.azurerm_subscription.current[0].id
  )
}

# --------------------------------------------------------------------------------------------------
# BUILT-IN POLICIES ASSIGNMENTS
# --------------------------------------------------------------------------------------------------

# Política 1: Requerir cifrado en Storage Accounts
data "azurerm_policy_definition" "require_storage_encryption" {
  display_name = "Storage accounts should use customer-managed key for encryption"
}

resource "azurerm_policy_assignment" "require_storage_encryption" {
  name                 = "require-storage-encryption"
  scope                = local.scope
  policy_definition_id = data.azurerm_policy_definition.require_storage_encryption.id
  description          = "Requiere customer-managed keys para cifrado (compliance PCI-DSS)"
  display_name         = "Require Storage Encryption with CMK"
  enforcement_mode     = var.enforcement_mode

  metadata = jsonencode({
    category = "Security"
    version  = "1.0.0"
  })
}

# Política 2: Denegar IPs públicas en VMs
data "azurerm_policy_definition" "deny_public_ip" {
  display_name = "Not allowed resource types"
}

resource "azurerm_policy_assignment" "deny_vm_public_ip" {
  name                 = "deny-vm-public-ip"
  scope                = local.scope
  policy_definition_id = data.azurerm_policy_definition.deny_public_ip.id
  description          = "Previene asignación de IPs públicas a VMs (security baseline)"
  display_name         = "Deny Public IP on VMs"
  enforcement_mode     = var.enforcement_mode

  parameters = jsonencode({
    listOfResourceTypesNotAllowed = {
      value = ["Microsoft.Compute/virtualMachines/publicIPAddresses"]
    }
  })
}

# Política 3: Requerir tags obligatorios
resource "azurerm_policy_definition" "require_tags" {
  name         = "require-mandatory-tags"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Require Mandatory Tags (Environment, CostCenter, Owner)"

  metadata = jsonencode({
    category = "Governance"
    version  = "1.0.0"
  })

  policy_rule = jsonencode({
    if = {
      anyOf = [
        {
          field  = "tags['Environment']"
          exists = "false"
        },
        {
          field  = "tags['CostCenter']"
          exists = "false"
        },
        {
          field  = "tags['Owner']"
          exists = "false"
        }
      ]
    }
    then = {
      effect = "deny"
    }
  })
}

resource "azurerm_policy_assignment" "require_tags" {
  name                 = "require-mandatory-tags"
  scope                = local.scope
  policy_definition_id = azurerm_policy_definition.require_tags.id
  description          = "Niega creación de recursos sin tags obligatorios (FinOps)"
  display_name         = "Require Tags: Environment, CostCenter, Owner"
  enforcement_mode     = var.enforcement_mode
}

# Política 4: Requerir TLS 1.2+ en todos los servicios
data "azurerm_policy_definition" "require_tls_12" {
  display_name = "App Service apps should use the latest TLS version"
}

resource "azurerm_policy_assignment" "require_tls_12" {
  name                 = "require-tls-12-minimum"
  scope                = local.scope
  policy_definition_id = data.azurerm_policy_definition.require_tls_12.id
  description          = "Requiere TLS 1.2 mínimo (PCI-DSS 3.2.1)"
  display_name         = "Require TLS 1.2+ for All Services"
  enforcement_mode     = var.enforcement_mode
}

# Política 5: Habilitar Microsoft Defender para todos los recursos
data "azurerm_policy_definition" "enable_defender" {
  display_name = "Azure Defender for servers should be enabled"
}

resource "azurerm_policy_assignment" "enable_defender" {
  name                 = "enable-defender-for-cloud"
  scope                = local.scope
  policy_definition_id = data.azurerm_policy_definition.enable_defender.id
  description          = "Habilita Azure Defender para detección de amenazas"
  display_name         = "Enable Microsoft Defender for Cloud"
  enforcement_mode     = var.enforcement_mode
}

# Política 6: Denegar regiones no aprobadas (data residency)
resource "azurerm_policy_definition" "allowed_locations" {
  name         = "allowed-azure-locations"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Allowed Azure Locations (Data Residency)"

  metadata = jsonencode({
    category = "Compliance"
    version  = "1.0.0"
  })

  parameters = jsonencode({
    allowedLocations = {
      type = "Array"
      metadata = {
        description = "Lista de ubicaciones permitidas"
        displayName = "Allowed Locations"
      }
    }
  })

  policy_rule = jsonencode({
    if = {
      not = {
        field = "location"
        in    = "[parameters('allowedLocations')]"
      }
    }
    then = {
      effect = "deny"
    }
  })
}

resource "azurerm_policy_assignment" "allowed_locations" {
  name                 = "enforce-allowed-locations"
  scope                = local.scope
  policy_definition_id = azurerm_policy_definition.allowed_locations.id
  description          = "Solo permite recursos en regiones aprobadas (Latam compliance)"
  display_name         = "Enforce Allowed Azure Regions"
  enforcement_mode     = var.enforcement_mode

  parameters = jsonencode({
    allowedLocations = {
      value = [
        "eastus",
        "eastus2",
        "brazilsouth" # Compliance Latam
      ]
    }
  })
}

# --------------------------------------------------------------------------------------------------
# RESOURCE LOCKS (Complemento a policies)
# --------------------------------------------------------------------------------------------------
resource "azurerm_management_lock" "prevent_deletion" {
  count = var.enforcement_mode == "Default" ? 1 : 0

  name       = "prevent-accidental-deletion"
  scope      = local.scope
  lock_level = "CanNotDelete"
  notes      = "Previene eliminación accidental de subscription/management group"
}

# --------------------------------------------------------------------------------------------------
# OUTPUTS
# --------------------------------------------------------------------------------------------------
output "policy_assignment_ids" {
  description = "IDs de las policy assignments creadas"
  value = {
    storage_encryption = azurerm_policy_assignment.require_storage_encryption.id
    deny_public_ip     = azurerm_policy_assignment.deny_vm_public_ip.id
    require_tags       = azurerm_policy_assignment.require_tags.id
    require_tls        = azurerm_policy_assignment.require_tls_12.id
    enable_defender    = azurerm_policy_assignment.enable_defender.id
    allowed_locations  = azurerm_policy_assignment.allowed_locations.id
  }
}

output "lock_id" {
  description = "ID del resource lock (si aplica)"
  value       = var.enforcement_mode == "Default" ? azurerm_management_lock.prevent_deletion[0].id : null
}
