# ==================================================================================================
# MÓDULO UTILITY - IPAM CALCULATOR
# ==================================================================================================
# Autor: Ronny Ortiz
# Propósito: Cálculo automático de subnets y validación de rangos IP
# ==================================================================================================

variable "vpc_cidr" {
  description = "CIDR block del VPC/VNet principal"
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR debe ser un bloque CIDR válido."
  }
}

variable "availability_zones" {
  description = "Lista de AZs para distribuir subnets"
  type        = list(string)
}

variable "enable_public_tier" {
  description = "Crear tier público (ALB, NAT Gateway)"
  type        = bool
  default     = true
}

variable "enable_app_tier" {
  description = "Crear tier de aplicación (EC2, containers)"
  type        = bool
  default     = true
}

variable "enable_data_tier" {
  description = "Crear tier de datos (RDS, cache)"
  type        = bool
  default     = true
}

# --------------------------------------------------------------------------------------------------
# SUBNET CALCULATIONS
# --------------------------------------------------------------------------------------------------
locals {
  az_count = length(var.availability_zones)

  # Subnet sizing strategy
  # VPC /16 → Public /22, App /20, Data /20 per AZ

  # Public Tier: /22 per AZ (1,019 IPs) - Small para ALB/NAT
  public_subnets = var.enable_public_tier ? [
    for idx in range(local.az_count) :
    cidrsubnet(var.vpc_cidr, 6, idx) # /16 + /6 = /22
  ] : []

  # App Tier: /20 per AZ (4,091 IPs) - Grande para instances
  app_subnets = var.enable_app_tier ? [
    for idx in range(local.az_count) :
    cidrsubnet(var.vpc_cidr, 4, idx + 16) # /16 + /4 = /20, offset 16
  ] : []

  # Data Tier: /20 per AZ (4,091 IPs) - Grande para DBs
  data_subnets = var.enable_data_tier ? [
    for idx in range(local.az_count) :
    cidrsubnet(var.vpc_cidr, 4, idx + 32) # /16 + /4 = /20, offset 32
  ] : []

  # Metadata para cada subnet
  public_subnet_metadata = [
    for idx, cidr in local.public_subnets : {
      name = "snet-public-${element(split("-", var.availability_zones[idx]), 2)}"
      cidr = cidr
      az   = var.availability_zones[idx]
      tier = "public"
    }
  ]

  app_subnet_metadata = [
    for idx, cidr in local.app_subnets : {
      name = "snet-app-${element(split("-", var.availability_zones[idx]), 2)}"
      cidr = cidr
      az   = var.availability_zones[idx]
      tier = "application"
    }
  ]

  data_subnet_metadata = [
    for idx, cidr in local.data_subnets : {
      name = "snet-data-${element(split("-", var.availability_zones[idx]), 2)}"
      cidr = cidr
      az   = var.availability_zones[idx]
      tier = "data"
    }
  ]
}

# --------------------------------------------------------------------------------------------------
# OUTPUTS
# --------------------------------------------------------------------------------------------------
output "public_subnets" {
  description = "CIDRs para subnets públicos"
  value       = local.public_subnets
}

output "app_subnets" {
  description = "CIDRs para subnets de aplicación"
  value       = local.app_subnets
}

output "data_subnets" {
  description = "CIDRs para subnets de datos"
  value       = local.data_subnets
}

output "public_subnet_metadata" {
  description = "Metadata completa de subnets públicos"
  value       = local.public_subnet_metadata
}

output "app_subnet_metadata" {
  description = "Metadata completa de subnets aplicación"
  value       = local.app_subnet_metadata
}

output "data_subnet_metadata" {
  description = "Metadata completa de subnets datos"
  value       = local.data_subnet_metadata
}

output "summary" {
  description = "Resumen de asignación de IPs"
  value = {
    vpc_cidr           = var.vpc_cidr
    total_ips          = pow(2, 32 - tonumber(split("/", var.vpc_cidr)[1]))
    public_subnets     = length(local.public_subnets)
    app_subnets        = length(local.app_subnets)
    data_subnets       = length(local.data_subnets)
    availability_zones = local.az_count
  }
}
