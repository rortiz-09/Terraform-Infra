# --------------------------------------------------------------------------------------------------
# Módulo de Networking Azure - VNet y Subnets
# Autor: Ronny
# Descripción: Crea Virtual Network con subnets dinámicos y NSG baseline
# --------------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------------
# VIRTUAL NETWORK (Base Connectivity)
# --------------------------------------------------------------------------------------------------
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
}

# --------------------------------------------------------------------------------------------------
# SUBNETS (Iteración dinámica)
# --------------------------------------------------------------------------------------------------
resource "azurerm_subnet" "subnet" {
  for_each             = var.subnets
  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [each.value]
}

# --------------------------------------------------------------------------------------------------
# NETWORK SECURITY GROUP (Baseline Security)
# --------------------------------------------------------------------------------------------------
resource "azurerm_network_security_group" "nsg_default" {
  name                = "nsg-${var.vnet_name}-default"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
