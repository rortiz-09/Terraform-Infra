# ==================================================================================================
# EJEMPLO: AWS Alcaldía Guayaquil - DEV (Patrón Enterprise)
# ==================================================================================================
# Autor: Ronny Ortiz
# Demo: Uso de data sources, locals condicionales, y naming module
# ==================================================================================================

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend remoto (descomentar para producción)
  # backend "s3" {
  #   bucket         = "terraform-state-alcaldia-guayaquil"
  #   key            = "dev/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

# --------------------------------------------------------------------------------------------------
# VARIABLES
# --------------------------------------------------------------------------------------------------
variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Ambiente de despliegue"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "alcaldia-guayaquil"
}

# --------------------------------------------------------------------------------------------------
# DATA SOURCES - DESCUBRIMIENTO DINÁMICO
# --------------------------------------------------------------------------------------------------
module "aws_data" {
  source = "../../../modules/data-sources"
}

# --------------------------------------------------------------------------------------------------
# NAMING CONVENTION
# --------------------------------------------------------------------------------------------------
module "naming" {
  source = "../../../../modules/utility/naming"

  organization = "municipio"
  project      = "alcaldia-gye"
  environment  = var.environment
  workload     = "web"
  region_code  = "use1"
}

# --------------------------------------------------------------------------------------------------
# CONFIGURACIÓN POR AMBIENTE (PATRÓN SENIOR)
# --------------------------------------------------------------------------------------------------
locals {
  # Configuración diferenciada por ambiente
  environment_config = {
    dev = {
      vpc_cidr         = "10.1.0.0/16"
      az_count         = 1 # Single AZ para dev (ahorro costos)
      instance_type    = "t3.small"
      enable_nat       = true  # 1 NAT Gateway
      enable_waf       = false # WAF solo en prod
      backup_retention = 7     # 1 semana
    }
    staging = {
      vpc_cidr         = "10.2.0.0/16"
      az_count         = 2
      instance_type    = "t3.medium"
      enable_nat       = true
      enable_waf       = true
      backup_retention = 14
    }
    prod = {
      vpc_cidr         = "10.0.0.0/16"
      az_count         = 3 # Multi-AZ para HA
      instance_type    = "m5.large"
      enable_nat       = true
      enable_waf       = true
      backup_retention = 30 # 1 mes
    }
  }

  # Selección automática basada en var.environment
  config = local.environment_config[var.environment]

  # AZs dinámicas (toma solo las necesarias según ambiente)
  availability_zones = slice(module.aws_data.availability_zones, 0, local.config.az_count)

  # Tags comunes usando módulo de naming
  common_tags = merge(
    module.naming.names.common_tags,
    {
      Application = "Recaudación Tributaria"
      Owner       = "Municipio de Guayaquil"
      CostCenter  = "Finanzas-Públicas"
    }
  )
}

# --------------------------------------------------------------------------------------------------
# NETWORKING MODULE CON CONFIGURACIÓN DINÁMICA
# --------------------------------------------------------------------------------------------------
module "networking" {
  source = "../../../modules/networking"

  vpc_cidr           = local.config.vpc_cidr
  project_name       = var.project_name
  environment        = var.environment
  availability_zones = local.availability_zones # Dinámico según ambiente
}

# --------------------------------------------------------------------------------------------------
# OUTPUTS ESTRUCTURADOS (PATRÓN ENTERPRISE)
# --------------------------------------------------------------------------------------------------
output "environment_info" {
  description = "Información del ambiente desplegado"
  value = {
    environment        = var.environment
    region             = module.aws_data.region
    availability_zones = local.availability_zones
    vpc_cidr           = local.config.vpc_cidr
  }
}

output "networking" {
  description = "Recursos de red creados"
  value = {
    vpc_id            = module.networking.vpc_id
    public_subnet_ids = module.networking.public_subnets
    app_subnet_ids    = module.networking.app_subnets
    data_subnet_ids   = module.networking.data_subnets
  }
}

output "resource_names" {
  description = "Nombres estandarizados de recursos"
  value       = module.naming.names
}
