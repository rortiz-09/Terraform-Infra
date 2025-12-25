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
# IMPLEMENTACIÓN DE ARQUITECTURA "PROD" (Alcaldía Guayaquil)
# --------------------------------------------------------------------------------------------------
# En producción desplegamos en 3 AZs para máxima tolerancia a fallos.

module "networking_prod" {
  source = "../../../modules/networking"

  vpc_cidr           = "10.0.0.0/16"
  project_name       = "guayaquil-recaudacion"
  environment        = "prod"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"] # Multi-AZ
}

# En producción agregamos WAF (definido en módulos de seguridad, referenciado aquí idealmente)
# y bases de datos RDS Multi-AZ en la subred de datos.
