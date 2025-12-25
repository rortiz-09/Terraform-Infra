terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg_health" {
  name     = "rg-salud-publica-prod"
  location = "Central US"
}

# --------------------------------------------------------------------------------------------------
# API GATEWAY (Interoperabilidad Hospitalaria)
# --------------------------------------------------------------------------------------------------
# Expone servicios HL7/FHIR de forma segura a terceros.
resource "azurerm_api_management" "apim" {
  name                = "apim-salud-ecuador-prod"
  location            = azurerm_resource_group.rg_health.location
  resource_group_name = azurerm_resource_group.rg_health.name
  publisher_name      = "Ministerio de Salud"
  publisher_email     = "admin@salud.gob.ec"
  sku_name            = "Premium_1" # Premium para red interna y multiregión

  virtual_network_type = "Internal" # Solo accesible dentro de la VPN gubernamental
}

# --------------------------------------------------------------------------------------------------
# BASE DE DATOS GLOBAL (Cosmos DB)
# --------------------------------------------------------------------------------------------------
# Historial médico con baja latencia de lectura en todo el país.
resource "azurerm_cosmosdb_account" "db" {
  name                = "cosmos-historias-clinicas"
  location            = azurerm_resource_group.rg_health.location
  resource_group_name = azurerm_resource_group.rg_health.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level = "Strong" # Consistencia fuerte para datos médicos críticos
  }

  geo_location {
    location          = "East US"
    failover_priority = 0
  }

  geo_location {
    location          = "West US"
    failover_priority = 1
  }
}
