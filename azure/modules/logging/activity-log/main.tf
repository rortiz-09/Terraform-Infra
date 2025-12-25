# ==================================================================================================
# MÓDULO: AZURE ACTIVITY LOG - LOGGING CENTRALIZADO
# ==================================================================================================
# Autor: Ronny Ortiz
# Propósito: Auditoría consolidada de operaciones en Azure (compliance SOC2, ISO 27001)
# WAF Pillar: Operational Excellence - Monitor & Log
# ==================================================================================================

variable "log_analytics_workspace_name" {
  description = "Nombre del Log Analytics Workspace"
  type        = string
}

variable "location" {
  description = "Ubicación de Azure"
  type        = string
}

variable "resource_group_name" {
  description = "Resource Group para el workspace"
  type        = string
}

variable "retention_days" {
  description = "Días de retención de logs (30-730)"
  type        = number
  default     = 90

  validation {
    condition     = var.retention_days >= 30 && var.retention_days <= 730
    error_message = "Retention debe estar entre 30 y 730 días."
  }
}

variable "storage_account_name" {
  description = "Storage Account para archivado de logs (opcional)"
  type        = string
  default     = null
}

# --------------------------------------------------------------------------------------------------
# LOG ANALYTICS WORKSPACE
# --------------------------------------------------------------------------------------------------
# Workspace centralizado para todos los logs de Azure
resource "azurerm_log_analytics_workspace" "main" {
  name                = var.log_analytics_workspace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018" # Pay-per-GB model
  retention_in_days   = var.retention_days

  tags = {
    Purpose = "Centralized Logging & Monitoring"
  }
}

# --------------------------------------------------------------------------------------------------
# DIAGNOSTIC SETTINGS - SUBSCRIPTION LEVEL
# --------------------------------------------------------------------------------------------------
# Envía Activity Logs de subscription a Log Analytics
data "azurerm_subscription" "current" {}

resource "azurerm_monitor_diagnostic_setting" "subscription" {
  name                       = "activity-logs-to-workspace"
  target_resource_id         = data.azurerm_subscription.current.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  storage_account_id         = var.storage_account_name

  # Categorías de logs a capturar
  enabled_log {
    category = "Administrative" # Crear, eliminar, actualizar recursos
  }

  enabled_log {
    category = "Security" # Cambios en RBAC, policies
  }

  enabled_log {
    category = "ServiceHealth" # Incidencias de Azure
  }

  enabled_log {
    category = "Alert" # Alertas disparadas
  }

  enabled_log {
    category = "Recommendation" # Advisor recommendations
  }

  enabled_log {
    category = "Policy" # Evaluaciones de Azure Policy
  }

  enabled_log {
    category = "Autoscale" # Eventos de auto-scaling
  }

  enabled_log {
    category = "ResourceHealth" # Estado de salud de recursos
  }
}

# --------------------------------------------------------------------------------------------------
# STORAGE ACCOUNT PARA ARCHIVADO (OPCIONAL)
# --------------------------------------------------------------------------------------------------
# Archivado económico de logs antiguos
resource "azurerm_storage_account" "logs" {
  count = var.storage_account_name != null ? 1 : 0

  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "GRS" # Geo-redundancia
  min_tls_version          = "TLS1_2"

  # Acceso de red restringido
  public_network_access_enabled = false

  tags = {
    Purpose = "Activity Logs Archive"
  }
}

# --------------------------------------------------------------------------------------------------
# ALERTAS CRÍTICAS
# --------------------------------------------------------------------------------------------------
# Alerta cuando se modifica configuración de seguridad
resource "azurerm_monitor_activity_log_alert" "security_changes" {
  name                = "critical-security-changes"
  resource_group_name = var.resource_group_name
  scopes              = [data.azurerm_subscription.current.id]
  description         = "Alerta de cambio crítico en configuración de seguridad"

  criteria {
    category = "Security"
  }

  action {
    action_group_id = azurerm_monitor_action_group.critical.id
  }
}

# Action Group para notificaciones
resource "azurerm_monitor_action_group" "critical" {
  name                = "critical-alerts"
  resource_group_name = var.resource_group_name
  short_name          = "CritAlerts"

  # Email notifications (configurar con variables)
  email_receiver {
    name          = "sendtoadmin"
    email_address = "admin@empresa.com" # Cambiar por variable
  }
}

# --------------------------------------------------------------------------------------------------
# OUTPUTS
# --------------------------------------------------------------------------------------------------
output "workspace_id" {
  description = "ID del Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "workspace_name" {
  description = "Nombre del workspace"
  value       = azurerm_log_analytics_workspace.main.name
}

output "workspace_key" {
  description = "Primary key del workspace (sensible)"
  value       = azurerm_log_analytics_workspace.main.primary_shared_key
  sensitive   = true
}
