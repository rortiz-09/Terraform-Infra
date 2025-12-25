# ==================================================================================================
# MÓDULO DE NETWORKING GCP - VPC Y SUBNETS
# ==================================================================================================
# Autor: Ronny Ortiz
# Propósito: Crear VPC en modo custom con subnets regionales
# Diferencias GCP: VPC es global, subnets son regionales (vs AWS donde VPC es regional)
# ==================================================================================================

# --------------------------------------------------------------------------------------------------
# VPC (VIRTUAL PRIVATE CLOUD) - GLOBAL
# --------------------------------------------------------------------------------------------------
# En GCP, la VPC es un recurso GLOBAL que abarca todas las regiones.
# - auto_create_subnetworks = false: Modo "custom" para control manual de subnets
# - Modo "auto" crearía automáticamente un subnet /20 en cada región (no recomendado)
resource "google_compute_network" "vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false # Modo custom para control total
  project                 = var.project_id

  # GCP VPC características únicas:
  # - Firewall rules se aplican a nivel VPC (no subnet)
  # - Routing es global por defecto
  # - VPC Peering permite conectar VPCs inter-proyecto
}

# --------------------------------------------------------------------------------------------------
# SUBNETS - REGIONALES CON ACCESO PRIVADO A GOOGLE APIS
# --------------------------------------------------------------------------------------------------
# Subnets en GCP son regionales (pueden abarcar múltiples zonas en la región).
# - Se crean dinámicamente desde variable tipo list
# - private_ip_google_access: Permite acceder a APIs de Google sin IP pública
resource "google_compute_subnetwork" "subnets" {
  count         = length(var.subnets)
  name          = var.subnets[count.index].name
  ip_cidr_range = var.subnets[count.index].cidr
  network       = google_compute_network.vpc.id
  region        = var.region
  project       = var.project_id

  # CRÍTICO: Permite que VMs sin IP pública accedan a:
  # - Cloud Storage, BigQuery, Cloud SQL, etc.
  # - Tráfico no sale a Internet, permanece en red de Google
  private_ip_google_access = true

  # Opcional: Habilitar flow logs para auditoría
  # log_config {
  #   aggregation_interval = "INTERVAL_5_SEC"
  #   flow_sampling        = 0.5
  # }
}
