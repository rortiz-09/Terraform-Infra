# --------------------------------------------------------------------------------------------------
# Variables del Módulo de Networking (AWS)
# Descripción: Define los parámetros configurables para la arquitectura de red 3-Tier
# Autor: Ronny
# --------------------------------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block para la VPC principal. Ejemplo: 10.0.0.0/16"
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr debe ser un bloque CIDR válido."
  }
}

variable "project_name" {
  description = "Nombre del proyecto para etiquetado de recursos. Usado en tags 'Name'"
  type        = string

  validation {
    condition     = length(var.project_name) > 0 && length(var.project_name) <= 50
    error_message = "project_name debe tener entre 1 y 50 caracteres."
  }
}

variable "environment" {
  description = "Ambiente de despliegue: dev, test o prod"
  type        = string

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment debe ser uno de: dev, test, prod."
  }
}

variable "availability_zones" {
  description = "Lista de zonas de disponibilidad (AZ) a usar. Se recomienda al menos 2 para prod"
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) > 0 && length(var.availability_zones) <= 6
    error_message = "Debe especificar entre 1 y 6 availability zones."
  }
}
