# --------------------------------------------------------------------------------------------------
# Variables - Industria Pronaca SAP Migration
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

variable "admin_ssh_public_key" {
  description = "Clave pública SSH para acceso a VMs Linux SAP (formato: ssh-rsa ...)"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^ssh-rsa|^ssh-ed25519|^ecdsa", var.admin_ssh_public_key))
    error_message = "La clave SSH debe comenzar con ssh-rsa, ssh-ed25519 o ecdsa."
  }
}
