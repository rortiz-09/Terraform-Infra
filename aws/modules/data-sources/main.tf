# ==================================================================================================
# DATA SOURCES - AWS DYNAMIC DISCOVERY
# ==================================================================================================
# Autor: Ronny Ortiz
# Propósito: Descubrimiento dinámico de recursos AWS (AMIs, AZs, Account ID)
# Beneficio: Elimina hardcodeo, mantiene actualizados los recursos base
# ==================================================================================================

# --------------------------------------------------------------------------------------------------
# ÚLTIMA AMI UBUNTU 22.04 LTS
# --------------------------------------------------------------------------------------------------
# Busca la AMI más reciente de Ubuntu publicada por Canonical
# Se actualiza automáticamente cuando Canonical publica nuevas versiones
data "aws_ami" "ubuntu_22_04" {
  most_recent = true
  owners      = ["099720109477"] # Canonical Official

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# --------------------------------------------------------------------------------------------------
# ÚLTIMA AMI AMAZON LINUX 2023
# --------------------------------------------------------------------------------------------------
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# --------------------------------------------------------------------------------------------------
# AVAILABILITY ZONES DISPONIBLES EN LA REGIÓN
# --------------------------------------------------------------------------------------------------
# Obtiene lista de AZs disponibles dinámicamente
# Útil para crear subnets en múltiples AZs sin hardcodear nombres
data "aws_availability_zones" "available" {
  state = "available"

  # Excluir AZs con capacidad limitada (Local Zones, Wavelength)
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# --------------------------------------------------------------------------------------------------
# INFORMACIÓN DE LA CUENTA AWS ACTUAL
# --------------------------------------------------------------------------------------------------
# Útil para construcción de ARNs y verificación de permisos
data "aws_caller_identity" "current" {}

# --------------------------------------------------------------------------------------------------
# REGIÓN ACTUAL
# --------------------------------------------------------------------------------------------------
data "aws_region" "current" {}

# --------------------------------------------------------------------------------------------------
# OUTPUTS PARA USO EN PROYECTOS
# --------------------------------------------------------------------------------------------------
output "ubuntu_ami_id" {
  description = "ID de la última AMI Ubuntu 22.04 LTS"
  value       = data.aws_ami.ubuntu_22_04.id
}

output "amazon_linux_ami_id" {
  description = "ID de la última AMI Amazon Linux 2023"
  value       = data.aws_ami.amazon_linux_2023.id
}

output "availability_zones" {
  description = "Lista de Availability Zones disponibles"
  value       = data.aws_availability_zones.available.names
}

output "account_id" {
  description = "ID de la cuenta AWS actual"
  value       = data.aws_caller_identity.current.account_id
}

output "region" {
  description = "Región AWS actual"
  value       = data.aws_region.current.name
}
