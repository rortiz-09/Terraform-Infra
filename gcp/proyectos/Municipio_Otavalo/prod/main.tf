terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = "otavalo-turismo-prod"
  region  = "us-central1"
}

# --------------------------------------------------------------------------------------------------
# RED PRODUCTIVA (Municipio Otavalo)
# --------------------------------------------------------------------------------------------------
module "networking_otavalo_prod" {
  source = "../../../modules/networking"

  project_id   = "otavalo-turismo-prod"
  region       = "us-central1"
  network_name = "vpc-otavalo-prod"

  subnets = [
    { name = "snet-cloudrun-connector", cidr = "10.10.0.0/28" }, # Connector para Serverless VPC Access
    { name = "snet-data-private", cidr = "10.10.1.0/24" }        # Bases de datos privadas
  ]
}

# Aqui irian los recursos de Cloud Run (Servicios Web) y BigQuery
