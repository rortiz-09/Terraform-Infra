# ==================================================================================================
# MÓDULO DE NETWORKING AWS - ARQUITECTURA 3-TIER VPC
# ==================================================================================================
# Autor: Ronny Ortiz
# Propósito: Crear una VPC con arquitectura de 3 capas para segregación de seguridad
# Capas: Public (ALB/Bastion), App (Servidores), Data (Bases de Datos)
# ==================================================================================================

# --------------------------------------------------------------------------------------------------
# VPC PRINCIPAL
# --------------------------------------------------------------------------------------------------
# Crea la Virtual Private Cloud que contendrá todos los recursos de red.
# - DNS habilitado para permitir resolución de nombres internos
# - CIDR configurable vía variable para flexibilidad multi-ambiente
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true # Permite asignar nombres DNS a instancias EC2
  enable_dns_support   = true # Habilita resolución DNS

  tags = {
    Name        = "vpc-${var.project_name}-${var.environment}"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Compliance  = "PCI-DSS" # Segregación de redes requerida por PCI-DSS
  }
}

# --------------------------------------------------------------------------------------------------
# INTERNET GATEWAY
# --------------------------------------------------------------------------------------------------
# Proporciona acceso a Internet para recursos en subnets públicas.
# Solo la capa pública tiene ruta directa al IGW.
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "igw-${var.project_name}-${var.environment}"
  }
}

# --------------------------------------------------------------------------------------------------
# SUBNETS - CAPA PÚBLICA
# --------------------------------------------------------------------------------------------------
# Subnets con acceso directo a Internet via IGW.
# Uso típico: Application Load Balancers, NAT Gateways, Bastion Hosts
# Se crea una subnet por cada AZ para alta disponibilidad
resource "aws_subnet" "public" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index) # /24 subnets
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "snet-public-${var.environment}-${element(split("-", var.availability_zones[count.index]), 2)}"
    Tier = "Public"
  }
}

# --------------------------------------------------------------------------------------------------
# SUBNETS - CAPA APLICACIÓN (PRIVADA)
# --------------------------------------------------------------------------------------------------
# Subnets privadas para servidores de aplicación.
# - Sin acceso directo entrante desde Internet
# - Salida a Internet via NAT Gateway para actualizaciones/APIs externas
# - Offset de +10 en el tercer octeto para evitar colisiones
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

# --------------------------------------------------------------------------------------------------
# SUBNETS - CAPA DATOS (AISLADA)
# --------------------------------------------------------------------------------------------------
# Subnets completamente privadas para bases de datos.
# - Sin salida a Internet por defecto (máxima seguridad)
# - Acceso solo desde capa App via Security Groups
# - Offset de +20 para separación clara
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
# NAT GATEWAY - SALIDA SEGURA A INTERNET
# --------------------------------------------------------------------------------------------------
# Permite que recursos en subnets privadas accedan a Internet de forma segura.
# - Una IP elástica por NAT Gateway para IP fija de salida
# - Desplegado en subnet pública para tener acceso al IGW
# - Costo: Se recomienda 1 por AZ en prod, 1 total en dev para ahorrar
resource "aws_eip" "nat" {
  count  = length(var.availability_zones)
  domain = "vpc" # Especifica que es para VPC, no EC2-Classic

  tags = {
    Name = "eip-nat-${var.project_name}-${var.environment}-az${count.index + 1}"
  }
}

resource "aws_nat_gateway" "main" {
  count         = length(var.availability_zones)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id # Debe estar en subnet pública

  # NAT Gateway requiere que el IGW esté creado primero
  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "nat-${var.project_name}-${var.environment}-${count.index}"
  }
}
