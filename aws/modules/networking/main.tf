variable "vpc_cidr" {
  description = "CIDR block para la VPC"
  type        = string
}

variable "project_name" {
  description = "Nombre del proyecto para etiquetado"
  type        = string
}

variable "environment" {
  description = "Ambiente de despliegue (dev, test, prod)"
  type        = string
}

variable "availability_zones" {
  description = "Lista de zonas de disponibilidad a usar"
  type        = list(string)
}

# --------------------------------------------------------------------------------------------------
# VPC BASE (Networking Core)
# --------------------------------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "vpc-${var.project_name}-${var.environment}"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Compliance  = "PCI-DSS" # (Segregación de redes requerida)
  }
}

# --------------------------------------------------------------------------------------------------
# INTERNET GATEWAY (Acceso Público Controlado)
# --------------------------------------------------------------------------------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "igw-${var.project_name}-${var.environment}"
  }
}

# --------------------------------------------------------------------------------------------------
# SUBNETS (Arquitectura 3-Capas)
# --------------------------------------------------------------------------------------------------

# Capa Publica: Balanceadores de Carga, Bastion Hosts
resource "aws_subnet" "public" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "snet-public-${var.environment}-${element(split("-", var.availability_zones[count.index]), 2)}"
    Tier = "Public"
  }
}

# Capa Aplicación (Privada): Servidores Web/App (Sin acceso directo internet inbound)
resource "aws_subnet" "app" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "snet-app-${var.environment}-${element(split("-", var.availability_zones[count.index]), 2)}"
    Tier = "App"
  }
}

# Capa Datos (Aislada): Bases de Datos, Caché (Sin salida a internet por defecto)
resource "aws_subnet" "data" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 20)
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "snet-data-${var.environment}-${element(split("-", var.availability_zones[count.index]), 2)}"
    Tier = "Data"
  }
}

# --------------------------------------------------------------------------------------------------
# NAT GATEWAY (Salida a Internet segura para capa App)
# --------------------------------------------------------------------------------------------------
# Solo creado en Producción/Test para ahorrar costos en dev si se desea (logic en main.tf del env)
resource "aws_eip" "nat" {
  count  = length(var.availability_zones)
  domain = "vpc"
}

resource "aws_nat_gateway" "main" {
  count         = length(var.availability_zones)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "nat-${var.project_name}-${var.environment}-${count.index}"
  }
}

# Salidas
output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnets" {
  value = aws_subnet.public[*].id
}

output "app_subnets" {
  value = aws_subnet.app[*].id
}
