# --------------------------------------------------------------------------------------------------
# Variables del Módulo de Networking (Azure)
# Descripción: Define los parámetros configurables para la creación de VNet y Subnets
# Autor: Ronny
# --------------------------------------------------------------------------------------------------

variable "resource_group_name" {
  description = "Nombre del Resource Group donde se crearán los recursos de red"
  type        = string
}

variable "location" {
  description = "Ubicación/Región de Azure (ej: East US, East US 2)"
  type        = string
}

variable "vnet_name" {
  description = "Nombre de la Virtual Network"
  type        = string

  validation {
    condition     = length(var.vnet_name) > 0 && length(var.vnet_name) <= 64
    error_message = "vnet_name debe tener entre 1 y 64 caracteres."
  }
}

variable "address_space" {
  description = "Espacio de direcciones CIDR para la VNet. Lista de bloques CIDR"
  type        = list(string)

  validation {
    condition     = length(var.address_space) > 0
    error_message = "Debe especificar al menos un bloque de direcciones."
  }
}

variable "subnets" {
  description = "Mapa de subnets a crear. Key = nombre, Value = CIDR del subnet"
  type        = map(string)

  validation {
    condition     = length(var.subnets) > 0
    error_message = "Debe definir al menos un subnet."
  }
}
