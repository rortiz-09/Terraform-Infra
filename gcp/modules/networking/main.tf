variable "project_id" { type = string }
variable "region" { type = string }
variable "network_name" { type = string }
variable "subnets" {
  description = "Lista de objetos subnet con nmbre y CIDR"
  type = list(object({
    name = string
    cidr = string
  }))
}

# --------------------------------------------------------------------------------------------------
# VPC (Global)
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
  region        = var.region
  network       = google_compute_network.vpc.id
  project       = var.project_id

  private_ip_google_access = true # Permite acceso a APIs de Google sin IP pública
}

output "network_self_link" { value = google_compute_network.vpc.self_link }
output "subnets_self_links" { value = google_compute_subnetwork.subnets[*].self_link }
