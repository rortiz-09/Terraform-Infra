# --------------------------------------------------------------------------------------------------
# Módulo de Networking GCP - VPC y Subnets
# Autor: Ronny
# Descripción: Crea VPC custom mode con subnets regionales
# --------------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------------
# VPC (Virtual Private Cloud)
# --------------------------------------------------------------------------------------------------
resource "google_compute_network" "vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false
  project                 = var.project_id
}

# --------------------------------------------------------------------------------------------------
# SUBNETS (Regional)
# --------------------------------------------------------------------------------------------------
resource "google_compute_subnetwork" "subnets" {
  count         = length(var.subnets)
  name          = var.subnets[count.index].name
  ip_cidr_range = var.subnets[count.index].cidr
  network       = google_compute_network.vpc.id
  region        = var.region
  project       = var.project_id

  # Acceso privado a Google APIs
  private_ip_google_access = true
}
