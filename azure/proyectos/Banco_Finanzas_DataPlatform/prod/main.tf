# --------------------------------------------------------------------------------------------------
# Created by Ronny
# Project: Banco Finanzas Data Platform
# License: MIT
# --------------------------------------------------------------------------------------------------

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  # Backend remoto - Descomentar y configurar para producción
  # backend "azurerm" {
  #   resource_group_name  = "rg-terraform-state"
  #   storage_account_name = "sttfstatebancoprod"
  #   container_name       = "tfstate"
  #   key                  = "banco-finanzas.terraform.tfstate"
  # }
}

provider "azurerm" {
  features {}
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
  }
}

resource "azurerm_resource_group" "rg_data" {
  name     = "rg-banco-data-analytics-${var.environment}"
  location = var.location
  tags     = local.common_tags
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
  account_replication_type = "ZRS"
  is_hns_enabled           = true

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }

  tags = local.common_tags
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

  managed_virtual_network_enabled = true
  public_network_access_enabled   = false

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

# Asignar permisos a la identidad de Synapse sobre el Data Lake
resource "azurerm_role_assignment" "synapse_storage_access" {
  scope                = azurerm_storage_account.datalake.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_synapse_workspace.analytics.identity[0].principal_id
}

resource "azurerm_synapse_sql_pool" "risk_pool" {
  name                 = "SyndpRiskProd"
  synapse_workspace_id = azurerm_synapse_workspace.analytics.id
  sku_name             = "DW1000c"
  create_mode          = "Default"

  tags = local.common_tags
}
