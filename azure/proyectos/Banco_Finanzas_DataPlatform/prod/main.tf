# ==================================================================================================
# PROYECTO: Banco Finanzas Data Platform - PRODUCTION
# ==================================================================================================
# WAF Aligned: Security, Reliability, Cost Optimization
# Autor: Ronny Ortiz
# ==================================================================================================

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  # Backend remoto (descomentar para producción)
  # backend "azurerm" {
  #   resource_group_name  = "rg-terraform-state"
  #   storage_account_name = "sttfstatebancoprod"
  #   container_name       = "tfstate"
  #   key                  = "banco-finanzas.terraform.tfstate"
  # }
}

provider "azurerm" {
  features {
    # Protección adicional para recursos críticos
    resource_group {
      prevent_deletion_if_contains_resources = true # WAF: Prevent accidental deletion
    }
    key_vault {
      purge_soft_delete_on_destroy = false # Conservar keys eliminadas
    }
  }
}

# --------------------------------------------------------------------------------------------------
# TAGS COMUNES (Estrategia de Etiquetado Consistente)
# --------------------------------------------------------------------------------------------------
locals {
  common_tags = {
    ManagedBy   = "Terraform"
    Environment = var.environment
    Owner       = "Ronny Ortiz"
    CostCenter  = var.cost_center
    Compliance  = "PCI-DSS/SOX"
    Project     = "Banco-DataPlatform"
    Criticality = "High"         # WAF: Tag for lifecycle policies
    DataClass   = "Confidential" # WAF: Data classification
  }
}

resource "azurerm_resource_group" "rg_data" {
  name     = "rg-banco-data-analytics-${var.environment}"
  location = var.location
  tags     = local.common_tags

  # WAF: Resource locks para producción
  lifecycle {
    prevent_destroy = var.environment == "prod" ? true : false
  }
}

# ==================================================================================================
# WAF INTEGRATION: LOGGING & MONITORING
# ==================================================================================================
module "activity_log" {
  source = "../../../modules/logging/activity-log"

  log_analytics_workspace_name = "law-banco-${var.environment}"
  resource_group_name          = azurerm_resource_group.rg_data.name
  location                     = azurerm_resource_group.rg_data.location
  retention_days               = var.environment == "prod" ? 365 : 90

  # Archivado en storage para compliance
  storage_account_name = var.environment == "prod" ? "stbancologsarchive${var.environment}" : null
}

# --------------------------------------------------------------------------------------------------
# NETWORKING (Modularidad Agregada)
# --------------------------------------------------------------------------------------------------
module "networking" {
  source = "../../../modules/networking"

  resource_group_name = azurerm_resource_group.rg_data.name
  location            = azurerm_resource_group.rg_data.location
  vnet_name           = "vnet-banco-analytics-${var.environment}"
  address_space       = ["10.180.0.0/16"]

  subnets = {
    "snet-data-endpoints" = "10.180.10.0/24"
  }
}

# --------------------------------------------------------------------------------------------------
# ALMACENAMIENTO SEGURO (Data Lake Gen2)
# --------------------------------------------------------------------------------------------------
resource "azurerm_storage_account" "datalake" {
  name                     = "stbancodatalake${var.environment}"
  resource_group_name      = azurerm_resource_group.rg_data.name
  location                 = azurerm_resource_group.rg_data.location
  account_tier             = "Standard"
  account_replication_type = var.environment == "prod" ? "ZRS" : "LRS" # WAF: HA in prod
  is_hns_enabled           = true
  min_tls_version          = "TLS1_2" # WAF: Security baseline

  # WAF: Network security
  public_network_access_enabled = false # Force private endpoints only

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }

  # WAF: Encryption at rest
  infrastructure_encryption_enabled = true

  # WAF: Soft delete y versioning
  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 30
    }

    container_delete_retention_policy {
      days = 30
    }
  }

  tags = merge(local.common_tags, {
    DataType = "Analytics"
  })

  lifecycle {
    prevent_destroy = var.environment == "prod" ? true : false

    ignore_changes = [
      # Ignorar cambios en tags de tracking automático
      tags["LastModified"]
    ]
  }
}

resource "azurerm_storage_data_lake_gen2_filesystem" "users" {
  name               = "users"
  storage_account_id = azurerm_storage_account.datalake.id
}

# --------------------------------------------------------------------------------------------------
# ANALÍTICA AVANZADA (Azure Synapse Analytics)
# --------------------------------------------------------------------------------------------------
resource "azurerm_synapse_workspace" "analytics" {
  name                                 = "syn-banco-riesgo-${var.environment}"
  resource_group_name                  = azurerm_resource_group.rg_data.name
  location                             = azurerm_resource_group.rg_data.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.users.id
  sql_administrator_login              = var.sql_administrator_login
  sql_administrator_login_password     = var.sql_administrator_password # Variable sensible

  # WAF: Security baseline
  managed_virtual_network_enabled = true
  public_network_access_enabled   = false

  # WAF: Managed identity (eliminapwd inline)
  identity {
    type = "SystemAssigned"
  }

  # WAF: Data exfiltration prevention
  data_exfiltration_protection_enabled = var.environment == "prod" ? true : false

  tags = local.common_tags

  lifecycle {
    prevent_destroy = var.environment == "prod" ? true : false
  }
}

# Asignar permisos con principio de mínimo privilegio
resource "azurerm_role_assignment" "synapse_storage_access" {
  scope                = azurerm_storage_account.datalake.id
  role_definition_name = "Storage Blob Data Contributor" # Mínimo necesario
  principal_id         = azurerm_synapse_workspace.analytics.identity[0].principal_id
}

resource "azurerm_synapse_sql_pool" "risk_pool" {
  name                 = "SyndpRiskProd"
  synapse_workspace_id = azurerm_synapse_workspace.analytics.id
  sku_name             = "DW1000c"
  create_mode          = "Default"

  tags = local.common_tags

  lifecycle {
    prevent_destroy = var.environment == "prod" ? true : false
  }
}

# --------------------------------------------------------------------------------------------------
# DIAGNOSTIC SETTINGS (Send logs to workspace)
# --------------------------------------------------------------------------------------------------
resource "azurerm_monitor_diagnostic_setting" "synapse" {
  name                       = "synapse-diagnostics"
  target_resource_id         = azurerm_synapse_workspace.analytics.id
  log_analytics_workspace_id = module.activity_log.workspace_id

  enabled_log {
    category = "SQLSecurityAuditEvents"
  }

  enabled_log {
    category = "BuiltinSqlReqsEnded"
  }

  metric {
    category = "AllMetrics"
  }
}
