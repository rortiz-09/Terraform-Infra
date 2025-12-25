# ==================================================================================================
# MÓDULO DE NETWORKING AWS - ARQUITECTURA 3-TIER CON IPAM
# ==================================================================================================
# Autor: Ronny Ortiz
# Propósito: VPC enterprise con segmentación Public/App/Data y IPAM integration
# Patrón: Hub-Spoke ready con Transit Gateway support
# ==================================================================================================

variable "vpc_cidr" {
  description = "CIDR block del VPC (debe estar en IPAM registry)"
  type        = string
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

variable "availability_zones" {
  description = "Lista de AZs para multi-AZ deployment"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Habilitar NAT Gateway para subnets privados"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Usar un solo NAT Gateway (cost saving para dev)"
  type        = bool
  default     = false
}

# --------------------------------------------------------------------------------------------------
# IPAM CALCULATOR - AUTO SUBNET CREATION
# --------------------------------------------------------------------------------------------------
module "ipam" {
  source = "../../../modules/utility/ipam-calculator"

  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  enable_public_tier = true
  enable_app_tier    = true
  enable_data_tier   = true
}

# --------------------------------------------------------------------------------------------------
# VPC
# --------------------------------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "vpc-${var.project_name}-${var.environment}"
    Environment = var.environment
    Tier        = "Network"
  }
}

# --------------------------------------------------------------------------------------------------
# INTERNET GATEWAY (Para Public Tier)
# --------------------------------------------------------------------------------------------------
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "igw-${var.project_name}-${var.environment}"
  }
}

# --------------------------------------------------------------------------------------------------
# PUBLIC SUBNETS (Tier 1: ALB, NAT Gateway)
# --------------------------------------------------------------------------------------------------
resource "aws_subnet" "public" {
  count = length(module.ipam.public_subnets)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = module.ipam.public_subnets[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${module.ipam.public_subnet_metadata[count.index].name}-${var.environment}"
    Tier = "Public"
  }
}

# --------------------------------------------------------------------------------------------------
# APPLICATION SUBNETS (Tier 2: EC2, Containers)
# --------------------------------------------------------------------------------------------------
resource "aws_subnet" "app" {
  count = length(module.ipam.app_subnets)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = module.ipam.app_subnets[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${module.ipam.app_subnet_metadata[count.index].name}-${var.environment}"
    Tier = "Application"
  }
}

# --------------------------------------------------------------------------------------------------
# DATA SUBNETS (Tier 3: RDS, ElastiCache)
# --------------------------------------------------------------------------------------------------
resource "aws_subnet" "data" {
  count = length(module.ipam.data_subnets)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = module.ipam.data_subnets[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${module.ipam.data_subnet_metadata[count.index].name}-${var.environment}"
    Tier = "Data"
  }
}

# --------------------------------------------------------------------------------------------------
# NAT GATEWAYS (Para outbound Internet desde subnets privados)
# --------------------------------------------------------------------------------------------------
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : 0
  domain = "vpc"

  tags = {
    Name = "eip-nat-${var.project_name}-${var.environment}-${count.index + 1}"
  }
}

resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "nat-${var.project_name}-${var.environment}-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.main]
}
