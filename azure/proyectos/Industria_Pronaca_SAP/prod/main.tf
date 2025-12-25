# --------------------------------------------------------------------------------------------------
# Created by Ronny
# Project: Industria Pronaca SAP Migration
# License: MIT
# --------------------------------------------------------------------------------------------------

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

resource "azurerm_resource_group" "rg_sap" {
  name     = "rg-pronaca-sap-prod"
  location = "East US 2"
}

# --------------------------------------------------------------------------------------------------
# NETWORKING (Módulo Modular)
# --------------------------------------------------------------------------------------------------
# Corrección: Ruta relativa ajustada (3 niveles arriba)
module "networking" {
  source = "../../../modules/networking"

  resource_group_name = azurerm_resource_group.rg_sap.name
  location            = azurerm_resource_group.rg_sap.location
  vnet_name           = "vnet-sap-prod"
  address_space       = ["10.150.0.0/16"]

  subnets = {
    "snet-sap-db"  = "10.150.10.0/24"
    "snet-sap-app" = "10.150.20.0/24"
  }
}

# --------------------------------------------------------------------------------------------------
# LATENCIA ULTRABAJA (Proximity Placement Group)
# --------------------------------------------------------------------------------------------------
resource "azurerm_proximity_placement_group" "sap_ppg" {
  name                = "ppg-sap-hana-prod"
  location            = azurerm_resource_group.rg_sap.location
  resource_group_name = azurerm_resource_group.rg_sap.name

  tags = {
    Workload = "SAP S/4HANA"
  }
}

# --------------------------------------------------------------------------------------------------
# COMPUTO CERTIFICADO SAP (Database Layer)
# --------------------------------------------------------------------------------------------------

resource "azurerm_network_interface" "hana_nic" {
  name                = "nic-hana-01"
  location            = azurerm_resource_group.rg_sap.location
  resource_group_name = azurerm_resource_group.rg_sap.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = module.networking.subnet_ids["snet-sap-db"]
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "hana_db" {
  name                            = "vm-pronaca-hana-01"
  resource_group_name             = azurerm_resource_group.rg_sap.name
  location                        = azurerm_resource_group.rg_sap.location
  size                            = "Standard_M64ms" # Serie M certificada para HANA
  admin_username                  = "sapadmin"
  proximity_placement_group_id    = azurerm_proximity_placement_group.sap_ppg.id
  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.hana_nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS" # OS disk debe ser Premium/Standard, no UltraSSD
  }

  source_image_reference {
    publisher = "SUSE"
    offer     = "SLES-SAP"
    sku       = "15-SP2"
    version   = "latest"
  }
}
