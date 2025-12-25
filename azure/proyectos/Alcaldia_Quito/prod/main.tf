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

resource "azurerm_resource_group" "rg_quito_prod" {
  name     = "rg-quito-corporativo-prod"
  location = "East US 2"
}

# --------------------------------------------------------------------------------------------------
# NETWORKING CORPORATIVO (PROD)
# --------------------------------------------------------------------------------------------------
module "networking_quito_prod" {
  source = "../../../modules/networking"

  resource_group_name = azurerm_resource_group.rg_quito_prod.name
  location            = azurerm_resource_group.rg_quito_prod.location
  vnet_name           = "vnet-quito-prod-001"
  address_space       = ["10.200.0.0/16"]

  # Segmentación funcional (Identity para DCs, App para aplicaciones internas)
  subnets = {
    "snet-identity" = "10.200.1.0/24"
    "snet-app-web"  = "10.200.10.0/24"
    "snet-db"       = "10.200.20.0/24"
    "GatewaySubnet" = "10.200.255.0/24" # Reservada para VPN Gateway
  }
}

# Aquí se agregarían módulos de Governance (Policies) y Compute.
