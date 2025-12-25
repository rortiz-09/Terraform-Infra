# ==================================================================================================
# MÓDULO UTILITY - NAMING CONVENTION
# ==================================================================================================
# Autor: Ronny Ortiz
# Propósito: Estandarizar nomenclatura de recursos en todos los proveedores cloud
# Patrón: {prefix}-{resource_type}-{project}-{environment}-{workload?}-{suffix?}
# ==================================================================================================

variable "organization" {
  description = "Nombre de la organización (ej: acme, empresa)"
  type        = string
}

variable "project" {
  description = "Nombre del proyecto (ej: ecommerce, dataplatform)"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment debe ser: dev, staging o prod."
  }
}

variable "workload" {
  description = "Tipo de carga de trabajo (opcional: web, api, db)"
  type        = string
  default     = ""
}

variable "region_code" {
  description = "Código de región (ej: use1, euw1, eus2)"
  type        = string
  default     = ""
}

# --------------------------------------------------------------------------------------------------
# NOMENCLATURA BASE
# --------------------------------------------------------------------------------------------------
locals {
  # Prefijo común para todos los recursos
  base_name = "${var.organization}-${var.project}-${var.environment}"

  # Sufijos opcionales
  workload_suffix = var.workload != "" ? "-${var.workload}" : ""
  region_suffix   = var.region_code != "" ? "-${var.region_code}" : ""

  # Función helper para generar nombres
  name_pattern = "${local.base_name}%s${local.workload_suffix}${local.region_suffix}"
}

# --------------------------------------------------------------------------------------------------
# NOMBRES POR TIPO DE RECURSO
# --------------------------------------------------------------------------------------------------
# Nomenclatura siguiendo Azure CAF y AWS/GCP best practices
output "names" {
  description = "Mapa de nombres estandarizados por tipo de recurso"
  value = {
    # Azure Resources
    resource_group         = "rg-${local.base_name}"
    virtual_network        = "vnet-${local.base_name}"
    subnet                 = "snet-${local.base_name}"
    network_security_group = "nsg-${local.base_name}"
    virtual_machine        = "vm-${local.base_name}${local.workload_suffix}"
    storage_account        = replace("st${var.organization}${var.project}${var.environment}", "-", "") # max 24 chars, no hyphens
    key_vault              = "kv-${local.base_name}"

    # AWS Resources
    vpc             = "vpc-${local.base_name}"
    ec2_instance    = "ec2-${local.base_name}${local.workload_suffix}"
    s3_bucket       = "${var.organization}-${var.project}-${var.environment}${local.workload_suffix}"
    lambda_function = "lambda-${local.base_name}${local.workload_suffix}"

    # GCP Resources
    compute_network  = "vpc-${local.base_name}"
    compute_instance = "vm-${local.base_name}${local.workload_suffix}"
    storage_bucket   = "${var.organization}-${var.project}-${var.environment}${local.workload_suffix}"

    # Tags comunes
    common_tags = {
      Organization = var.organization
      Project      = var.project
      Environment  = var.environment
      ManagedBy    = "Terraform"
      Workload     = var.workload
    }
  }
}
