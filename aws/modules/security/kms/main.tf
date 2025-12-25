# ==================================================================================================
# MÓDULO: KMS - CIFRADO EN REPOSO
# ==================================================================================================
# Autor: Ronny Ortiz
# Propósito: Gestión centralizada de claves de cifrado (compliance HIPAA, PCI-DSS)
# WAF Pillar: Security - Protect data at rest
# ==================================================================================================

variable "key_description" {
  description = "Descripción de la KMS key"
  type        = string
  default     = "Main encryption key for data at rest"
}

variable "key_deletion_window" {
  description = "Días de espera antes de eliminar key (7-30)"
  type        = number
  default     = 30

  validation {
    condition     = var.key_deletion_window >= 7 && var.key_deletion_window <= 30
    error_message = "Deletion window debe estar entre 7 y 30 días."
  }
}

variable "enable_key_rotation" {
  description = "Habilitar rotación automática anual"
  type        = bool
  default     = true
}

variable "key_administrators" {
  description = "ARNs de IAM users/roles que administran la key"
  type        = list(string)
  default     = []
}

variable "key_users" {
  description = "ARNs de IAM users/roles/services que usan la key"
  type        = list(string)
  default     = []
}

# --------------------------------------------------------------------------------------------------
# DATA SOURCES
# --------------------------------------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# --------------------------------------------------------------------------------------------------
# KMS KEY
# --------------------------------------------------------------------------------------------------
resource "aws_kms_key" "main" {
  description             = var.key_description
  deletion_window_in_days = var.key_deletion_window
  enable_key_rotation     = var.enable_key_rotation
  multi_region            = false # Cambiar a true  si se requiere multi-región

  # Policy que permite administración y uso
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        # Root account siempre puede administrar (previene lockout)
        {
          Sid    = "Enable IAM User Permissions"
          Effect = "Allow"
          Principal = {
            AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
          }
          Action   = "kms:*"
          Resource = "*"
        }
      ],
      # Administradores de la key
      length(var.key_administrators) > 0 ? [{
        Sid    = "Allow Key Administrators"
        Effect = "Allow"
        Principal = {
          AWS = var.key_administrators
        }
        Action = [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion"
        ]
        Resource = "*"
      }] : [],
      # Usuarios/servicios que cifran/descifran
      length(var.key_users) > 0 ? [{
        Sid    = "Allow Key Usage"
        Effect = "Allow"
        Principal = {
          AWS = var.key_users
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }] : [],
      # Permitir AWS services comunes (S3, EBS, RDS, etc.)
      [{
        Sid    = "Allow AWS Services"
        Effect = "Allow"
        Principal = {
          Service = [
            "s3.amazonaws.com",
            "ec2.amazonaws.com",
            "rds.amazonaws.com",
            "logs.amazonaws.com",
            "cloudtrail.amazonaws.com"
          ]
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }]
    )
  })

  tags = {
    Purpose  = "Data Encryption at Rest"
    Rotation = var.enable_key_rotation ? "Enabled" : "Disabled"
  }
}

# Alias para identificación fácil
resource "aws_kms_alias" "main" {
  name          = "alias/${var.key_description != "" ? replace(lower(var.key_description), " ", "-") : "default-encryption-key"}"
  target_key_id = aws_kms_key.main.key_id
}

# --------------------------------------------------------------------------------------------------
# OUTPUTS
# --------------------------------------------------------------------------------------------------
output "key_id" {
  description = "ID de la KMS key"
  value       = aws_kms_key.main.key_id
}

output "key_arn" {
  description = "ARN de la KMS key (para policies)"
  value       = aws_kms_key.main.arn
}

output "key_alias" {
  description = "Alias de la KMS key"
  value       = aws_kms_alias.main.name
}
