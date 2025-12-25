# ==================================================================================================
# MÓDULO DE NETWORKING AZURE - VNET Y SUBNETS
# ==================================================================================================
# Autor: Ronny Ortiz
# Propósito: Crear Virtual Network con subnets dinámicos y NSG baseline de seguridad
# Patrón: Hub-Spoke ready (este módulo puede ser un Spoke)
# ==================================================================================================

# --------------------------------------------------------------------------------------------------
# VIRTUAL NETWORK (VNET)
# --------------------------------------------------------------------------------------------------
# Red virtual aislada en Azure. Equivalente a VPC en AWS.
# - Address space: Define el rango CIDR completo (ej: 10.0.0.0/16)
# - Subnets: Se crean dinámicamente desde variable tipo map
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space # Puede ser múltiples CIDRs
}

# --------------------------------------------------------------------------------------------------
# SUBNETS - CREACIÓN DINÁMICA
# --------------------------------------------------------------------------------------------------
# Utiliza for_each para crear múltiples subnets desde un map variable.
# Ejemplo de uso:
#   subnets = {
#     "snet-web"  = "10.0.1.0/24"
#     "snet-data" = "10.0.2.0/24"
#   }
# Permite agregar/quitar subnets sin modificar el código del módulo
resource "azurerm_subnet" "subnet" {
  for_each             = var.subnets
  name                 = each.key # Nombre del subnet (key del map)
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [each.value] # CIDR del subnet (value del map)
}

# --------------------------------------------------------------------------------------------------
# NETWORK SECURITY GROUP (NSG) - SEGURIDAD BASELINE
# --------------------------------------------------------------------------------------------------
# NSG por defecto con política de denegación total entrante.
# Propósito: Establecer postura de seguridad "deny by default"
# Cada proyecto debe crear reglas específicas permitiendo solo tráfico necesario
resource "azurerm_network_security_group" "nsg_default" {
  name                = "nsg-${var.vnet_name}-default"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Regla de prioridad más baja (4096 = última en evaluarse)
  # Bloquea TODO el tráfico entrante que no coincida con reglas previas
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096 # Prioridad más baja
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*" # Todos los protocolos
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*" # Desde cualquier origen
    destination_address_prefix = "*"
  }

  # Nota: Reglas Allow específicas deben agregarse con prioridad < 4096
  # Ejemplo: Allow HTTPS (443) desde Internet = priority 100
}
