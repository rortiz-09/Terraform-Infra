# ==================================================================================================
# MÓDULO: CLOUDTRAIL - LOGGING CENTRALIZADO
# ==================================================================================================
# Autor: Ronny Ortiz
# Propósito: Auditoría consolidada de todas las acciones en AWS (compliance SOC2, PCI-DSS)
# WAF Pillar: Security - Enable logging & monitoring
# ==================================================================================================

variable "trail_name" {
  description = "Nombre del CloudTrail"
  type        = string
  default     = "organization-audit-trail"
}

variable "s3_bucket_name" {
  description = "Bucket S3 para almacenar logs (debe existir previamente)"
  type        = string
}

variable "enable_log_file_validation" {
  description = "Habilitar validación de integridad de logs (hash)"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key para cifrar logs en S3"
  type        = string
  default     = null
}

# --------------------------------------------------------------------------------------------------
# S3 BUCKET PARA CLOUDTRAIL LOGS
# --------------------------------------------------------------------------------------------------
# Bucket dedicado con políticas de acceso restringidas
resource "aws_s3_bucket" "cloudtrail" {
  bucket = var.s3_bucket_name

  lifecycle {
    prevent_destroy = true # Crítico: evitar pérdida de audit logs
  }

  tags = {
    Purpose  = "CloudTrail Audit Logs"
    Critical = "true"
  }
}

# Bloquear acceso público al bucket de logs
resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Cifrado server-side obligatorio
resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_id != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_id
    }
  }
}

# Lifecycle policy para archivado
resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    id     = "archive-old-logs"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "GLACIER" # Archivado económico
    }

    expiration {
      days = 365 # Retención 1 año (ajustar según compliance)
    }
  }
}

# Bucket policy para permitir CloudTrail escribir
resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# --------------------------------------------------------------------------------------------------
# CLOUDTRAIL - MULTI-REGIÓN
# --------------------------------------------------------------------------------------------------
resource "aws_cloudtrail" "main" {
  name                          = var.trail_name
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  include_global_service_events = true # IAM, STS, etc.
  is_multi_region_trail         = true # Todas las regiones
  enable_log_file_validation    = var.enable_log_file_validation
  kms_key_id                    = var.kms_key_id

  # Capturar eventos de lectura y escritura
  event_selector {
    read_write_type           = "All"
    include_management_events = true

    # Auditar acceso a S3
    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::*/"]
    }

    # Auditar ejecuciones Lambda
    data_resource {
      type   = "AWS::Lambda::Function"
      values = ["arn:aws:lambda:*:*:function/*"]
    }
  }

  # CloudWatch Logs integration (opcional pero recomendado)
  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_cloudwatch.arn

  depends_on = [aws_s3_bucket_policy.cloudtrail]
}

# --------------------------------------------------------------------------------------------------
# CLOUDWATCH LOGS INTEGRATION
# --------------------------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudtrail/${var.trail_name}"
  retention_in_days = 90
  kms_key_id        = var.kms_key_id
}

resource "aws_iam_role" "cloudtrail_cloudwatch" {
  name = "${var.trail_name}-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "cloudtrail.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "cloudtrail_cloudwatch" {
  name = "cloudtrail-cloudwatch-logs"
  role = aws_iam_role.cloudtrail_cloudwatch.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
    }]
  })
}

# --------------------------------------------------------------------------------------------------
# OUTPUTS
# --------------------------------------------------------------------------------------------------
output "trail_arn" {
  description = "ARN del CloudTrail"
  value       = aws_cloudtrail.main.arn
}

output "s3_bucket_name" {
  description = "Bucket S3 con los logs"
  value       = aws_s3_bucket.cloudtrail.id
}

output "cloudwatch_log_group" {
  description = "CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.cloudtrail.name
}
