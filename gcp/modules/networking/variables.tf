# --------------------------------------------------------------------------------------------------
# Variables del Módulo de Networking (GCP)
# Descripción: Define los parámetros configurables para la creación de VPC y Subnets
# Autor: Ronny
# --------------------------------------------------------------------------------------------------

variable "project_id" {
  description = "ID del proyecto de GCP donde se crearán los recursos"
  type        = string
}

variable "region" {
  description = "Región de GCP (ej: us-central1, us-east1)"
  type        = string
}

variable "network_name" {
  description = "Nombre de la VPC/Network"
  type        = string

  validation {
    condition     = length(var.network_name) > 0 && length(var.network_name) <= 63
    error_message = "network_name debe tener entre 1 y 63 caracteres."
  }
}

variable "subnets" {
  description = "Lista de subnets a crear con nombre y CIDR"
  type = list(object({
    name = string
    cidr = string
  }))

  validation {
    condition     = length(var.subnets) > 0
    error_message = "Debe definir al menos un subnet."
  }
}
