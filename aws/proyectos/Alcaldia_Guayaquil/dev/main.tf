# ==================================================================================================
# PROYECTO: Alcaldía de Guayaquil - DESARROLLO
# ==================================================================================================
# Unidad Organizativa: Gobierno
# IPAM: 10.64.0.0/16 (AWS Dev - ver docs/IPAM_REGISTRY.md)
# Autor: Ronny Ortiz
# ==================================================================================================

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "Alcaldía Guayaquil"
      Environment = "dev"
      ManagedBy   = "Terraform"
      OU          = "Gobierno"
      CostCenter  = "GYE-DEV"
    }
  }
}

# --------------------------------------------------------------------------------------------------
# DATA SOURCES - Dynamic Discovery
# --------------------------------------------------------------------------------------------------
data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# --------------------------------------------------------------------------------------------------
# NETWORKING - 3-Tier Architecture con IPAM
# --------------------------------------------------------------------------------------------------
# Usa CIDR registrado en IPAM: 10.64.0.0/16
# Tier strategy: Public(/22), App(/20), Data(/20) por AZ
module "networking" {
  source = "../../../modules/networking"

  vpc_cidr           = "10.64.0.0/16" # Desde IPAM Registry
  project_name       = "alcaldia-guayaquil"
  environment        = "dev"
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 1) # 1 AZ para dev (cost saving)

  # Dev: Single NAT Gateway para reducir costos
  enable_nat_gateway = true
  single_nat_gateway = true
}

# --------------------------------------------------------------------------------------------------
# OUTPUTS
# --------------------------------------------------------------------------------------------------
output "vpc_id" {
  description = "ID del VPC creado"
  value       = module.networking.vpc_id
}

output "networking_summary" {
  description = "Resumen de red desplegada"
  value = {
    vpc_cidr        = module.networking.vpc_cidr
    public_subnets  = module.networking.public_subnets
    app_subnets     = module.networking.app_subnets
    data_subnets    = module.networking.data_subnets
    nat_gateway_ips = module.networking.nat_gateway_ips
    ipam_summary    = module.networking.ipam_summary
  }
}
