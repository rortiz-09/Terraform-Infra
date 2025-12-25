# --------------------------------------------------------------------------------------------------
# Outputs del Módulo de Networking (Azure)
# Descripción: Expone los IDs de VNet y Subnets creados
# Autor: Ronny
# --------------------------------------------------------------------------------------------------

output "vnet_id" {
  description = "ID de la Virtual Network creada"
  value       = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  description = "Nombre de la Virtual Network"
  value       = azurerm_virtual_network.vnet.name
}

output "subnet_ids" {
  description = "Mapa de IDs de subnets (key = nombre del subnet, value = ID)"
  value       = { for k, v in azurerm_subnet.subnet : k => v.id }
}

output "nsg_id" {
  description = "ID del Network Security Group por defecto"
  value       = azurerm_network_security_group.nsg_default.id
}
