terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = "fintech-openbanking-prod"
  region  = "us-central1"
}

# --------------------------------------------------------------------------------------------------
# SEGURIDAD DE APIS (Cloud Armor)
# --------------------------------------------------------------------------------------------------
resource "google_compute_security_policy" "api_defense" {
  name = "policy-api-banca-abierta"

  rule {
    action   = "deny(403)"
    priority = "1000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["9.9.9.0/24"] # Blacklist simulada
      }
    }
    description = "Bloqueo de IPs maliciosas conocidas"
  }

  rule {
    action   = "allow"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Default allow"
  }
}
