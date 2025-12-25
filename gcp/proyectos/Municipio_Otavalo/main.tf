terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = "otavalo-turismo-digital-2025"
  region  = "us-central1"
  zone    = "us-central1-a"
}

# --------------------------------------------------------------------------------------------------
# INNOVACIÓN TURÍSTICA (Aplicación "Otavalo Digital")
# --------------------------------------------------------------------------------------------------
# Despliegue Serverless con Cloud Run para optimizar costos (paga por uso).
# Ideal para aplicaciones que pueden tener tráfico variable dependiendo de temporada turística.
resource "google_cloud_run_service" "turismo_app" {
  name     = "app-turismo-otavalo"
  location = "us-central1"

  template {
    spec {
      containers {
        image = "gcr.io/google-samples/hello-app:1.0" # Placeholder para imagen real
        resources {
          limits = {
            cpu    = "1000m"
            memory = "512Mi" # Optimización de memoria para reducir costos
          }
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  autogenerate_revision_name = true
}

# Hacer el servicio público para turistas
data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location    = google_cloud_run_service.turismo_app.location
  project     = google_cloud_run_service.turismo_app.project
  service     = google_cloud_run_service.turismo_app.name
  policy_data = data.google_iam_policy.noauth.policy_data
}

# --------------------------------------------------------------------------------------------------
# ANALÍTICA DE DATOS (Turismo Inteligente)
# --------------------------------------------------------------------------------------------------
# BigQuery para analizar datos demográficos de visitantes y planificar eventos culturales.
resource "google_bigquery_dataset" "analytics_turismo" {
  dataset_id                  = "otavalo_analytics_turismo"
  friendly_name               = "Analytics Turismo"
  description                 = "Datos anonimizados de afluencia turística"
  location                    = "US"
  default_table_expiration_ms = 3600000 # 1 hora (ejemplo gestión costos almacenamiento)

  labels = {
    env = "produccion"
  }
}

# --------------------------------------------------------------------------------------------------
# ALMACENAMIENTO DE ACTIVOS (Mapas, Guías PDF)
# --------------------------------------------------------------------------------------------------
resource "google_storage_bucket" "activos_turismo" {
  name          = "otavalo-turismo-assets-public"
  location      = "US"
  force_destroy = true

  uniform_bucket_level_access = true

  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }

  # Cost-Optimization: Usar clase Standard pero considerar Nearline para backups
  storage_class = "STANDARD"
}
