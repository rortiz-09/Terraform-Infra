# --------------------------------------------------------------------------------------------------
# Outputs del Módulo de Networking (GCP)
# Descripción: Expone los self-links de VPC y Subnets creados
# Autor: Ronny
# --------------------------------------------------------------------------------------------------

output "network_self_link" {
  description = "Self-link de la VPC creada (para referencias en otros recursos)"
  value       = google_compute_network.vpc.self_link
}

output "network_name" {
  description = "Nombre de la VPC"
  value       = google_compute_network.vpc.name
}

output "subnets_self_links" {
  description = "Lista de self-links de los subnets creados"
  value       = google_compute_subnetwork.subnets[*].self_link
}

output "subnets_names" {
  description = "Lista de nombres de los subnets creados"
  value       = google_compute_subnetwork.subnets[*].name
}
