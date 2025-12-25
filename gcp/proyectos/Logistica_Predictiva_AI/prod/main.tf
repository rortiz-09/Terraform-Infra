terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = "logistica-ai-prod"
  region  = "us-central1"
}

# --------------------------------------------------------------------------------------------------
# INTELIGENCIA ARTIFICIAL (Vertex AI)
# --------------------------------------------------------------------------------------------------
resource "google_vertex_ai_dataset" "inventory_data" {
  display_name        = "ds-inventario-historico"
  metadata_schema_uri = "gs://google-cloud-aiplatform/schema/dataset/metadata/tabular_1.0.0.yaml"
  region              = "us-central1"

  labels = {
    env = "produccion"
  }
}

resource "google_bigquery_dataset" "ml_input" {
  dataset_id  = "bq_logistica_input"
  description = "Dataset para ingesta de datos de sensores de almacén"
  location    = "US"
}
