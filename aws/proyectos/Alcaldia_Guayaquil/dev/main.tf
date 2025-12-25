terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# --------------------------------------------------------------------------------------------------
# IMPLEMENTACIÓN DE ARQUITECTURA "DEV" (Alcaldía Guayaquil)
# --------------------------------------------------------------------------------------------------
# En desarrollo usamos una sola AZ para ahorrar costos.

module "networking_dev" {
  source = "../../../modules/networking"

  vpc_cidr           = "10.1.0.0/16"
  project_name       = "guayaquil-recaudacion"
  environment        = "dev"
  availability_zones = ["us-east-1a"] # Single AZ para desarrollo
}

# Recursos adicionales para este ambiente (ej. Instancia Bastion pequeña)
resource "aws_instance" "bastion_dev" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"
  subnet_id     = module.networking_dev.public_subnets[0]

  tags = {
    Name = "srv-bastion-dev"
  }
}
