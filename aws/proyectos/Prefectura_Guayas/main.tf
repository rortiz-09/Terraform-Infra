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
  default_tags {
    tags = {
      Proyecto   = "Gestion Vialidad Provincial"
      Entidad    = "Prefectura del Guayas"
      Ambiente   = "Produccion"
      Compliance = "Ley Proteccion Datos Ecuador"
    }
  }
}

# --------------------------------------------------------------------------------------------------
# ALMACENAMIENTO SEGURO Y ARCHIVADO (Gestión Documental Obras)
# --------------------------------------------------------------------------------------------------
# Bucket S3 para almacenar planos y documentos de obras civiles.
# Reglas de ciclo de vida para optimizar costos moviendo datos antiguos a Glacier.
resource "aws_s3_bucket" "obras_archive" {
  bucket = "prefectura-guayas-obras-vialidad-archive"

  # Encriptación en reposo (ISO 27001 - Cifrado)
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "archivo_historico" {
  bucket = aws_s3_bucket.obras_archive.id

  rule {
    id     = "ArchivarObrasAntiguas"
    status = "Enabled"

    filter {
      prefix = "documentos/2020/"
    }

    # Transición a almacenamiento mas económico despues de 90 dias
    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    # Archivo profundo (Glacier) despues de 1 año (Cumplimiento legal)
    transition {
      days          = 365
      storage_class = "GLACIER"
    }
  }
}

# --------------------------------------------------------------------------------------------------
# INTERNET DE LAS COSAS (IoT) - Monitoreo de Peajes y Clima
# --------------------------------------------------------------------------------------------------
# Registro de dispositivos IoT para sensores instalados en carreteras provinciales.
resource "aws_iot_thing" "sensor_vialidad" {
  name = "Sensor-Peaje-Yaguachi-01"

  attributes = {
    modelo    = "SensorX-2025"
    ubicacion = "Vía Yaguachi"
    tipo      = "Trafico/Clima"
  }
}

resource "aws_iot_policy" "pubsub" {
  name = "Politica_Sensores_Vialidad"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "iot:Connect",
          "iot:Publish",
          "iot:Subscribe",
          "iot:Receive"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}
