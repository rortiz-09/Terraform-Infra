# --------------------------------------------------------------------------------------------------
# Variables - Banco Finanzas Data Platform
# Autor: Ronny
# --------------------------------------------------------------------------------------------------

variable "environment" {
  description = "Ambiente de despliegue"
  type        = string
  default     = "prod"
}

variable "location" {
  description = "Ubicación de Azure"
  type        = string
  default     = "East US 2"
}

variable "sql_administrator_login" {
  description = "Usuario administrador de SQL"
  type        = string
  default     = "sqladminuser"
}

variable "sql_administrator_password" {
  description = "Contraseña del administrador SQL (NUNCA hardcodear)"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.sql_administrator_password) >= 12
    error_message = "La contraseña debe tener al menos 12 caracteres."
  }
}

variable "cost_center" {
  description = "Centro de costos para facturación"
  type        = string
  default     = "RiesgoCrediticio"
}
