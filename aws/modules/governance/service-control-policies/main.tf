# ==================================================================================================
# MÓDULO: AWS SERVICE CONTROL POLICIES (SCP)
# ==================================================================================================
# Autor: Ronny Ortiz
# Propósito: Guardrails preventivos a nivel de AWS Organizations
# WAF Pillar: Security - Preventive controls
# ==================================================================================================

variable "organization_id" {
  description = "ID de AWS Organization (opcional si ya existe)"
  type        = string
  default     = null
}

variable "enable_deny_root_actions" {
  description = "Denegar acciones con root account (best practice)"
  type        = bool
  default     = true
}

variable "require_mfa_for_sensitive_actions" {
  description = "Requerir MFA para acciones destructivas"
  type        = bool
  default     = true
}

variable "prevent_leaving_organization" {
  description = "Prevenir que cuentas salgan de la organización"
  type        = bool
  default     = true
}

# --------------------------------------------------------------------------------------------------
# POLÍTICA: PREVENIR ELIMINACIÓN DE RECURSOS CRÍTICOS
# --------------------------------------------------------------------------------------------------
resource "aws_organizations_policy" "prevent_critical_resource_deletion" {
  name        = "PreventCriticalResourceDeletion"
  description = "Niega eliminación de recursos taggeados como Critical=true"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyDeleteCriticalResources"
        Effect = "Deny"
        Action = [
          "rds:DeleteDBInstance",
          "rds:DeleteDBCluster",
          "s3:DeleteBucket",
          "dynamodb:DeleteTable",
          "ec2:TerminateInstances",
          "kms:ScheduleKeyDeletion"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/Critical" = "true"
          }
        }
      }
    ]
  })

  type = "SERVICE_CONTROL_POLICY"
}

# --------------------------------------------------------------------------------------------------
# POLÍTICA: DENEGAR ACCIONES CON ROOT ACCOUNT
# --------------------------------------------------------------------------------------------------
resource "aws_organizations_policy" "deny_root_account" {
  count = var.enable_deny_root_actions ? 1 : 0

  name        = "DenyRootAccountActions"
  description = "Previene uso de root account para operaciones (CIS Benchmark 1.1)"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyRootUser"
        Effect   = "Deny"
        Action   = "*"
        Resource = "*"
        Condition = {
          StringLike = {
            "aws:PrincipalArn" = "arn:aws:iam::*:root"
          }
        }
      }
    ]
  })

  type = "SERVICE_CONTROL_POLICY"
}

# --------------------------------------------------------------------------------------------------
# POLÍTICA: REQUERIR MFA PARA ACCIONES SENSIBLES
# --------------------------------------------------------------------------------------------------
resource "aws_organizations_policy" "require_mfa" {
  count = var.require_mfa_for_sensitive_actions ? 1 : 0

  name        = "RequireMFAForSensitiveActions"
  description = "Requiere MFA para acciones destructivas y cambios de IAM"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyActionsWithoutMFA"
        Effect = "Deny"
        Action = [
          "iam:DeleteUser",
          "iam:DeleteRole",
          "iam:DeleteAccessKey",
          "ec2:TerminateInstances",
          "rds:DeleteDBInstance",
          "s3:DeleteBucket"
        ]
        Resource = "*"
        Condition = {
          BoolIfExists = {
            "aws:MultiFactorAuthPresent" = "false"
          }
        }
      }
    ]
  })

  type = "SERVICE_CONTROL_POLICY"
}

# --------------------------------------------------------------------------------------------------
# POLÍTICA: DENEGAR REGIONES NO APROBADAS
# --------------------------------------------------------------------------------------------------
resource "aws_organizations_policy" "deny_unapproved_regions" {
  name        = "DenyUnapprovedRegions"
  description = "Solo permite operaciones en regiones aprobadas (data residency)"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyAllOutsideApprovedRegions"
        Effect = "Deny"
        NotAction = [
          "iam:*",
          "organizations:*",
          "route53:*",
          "cloudfront:*",
          "support:*",
          "budgets:*"
        ]
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:RequestedRegion" = [
              "us-east-1",
              "us-west-2",
              "sa-east-1" # São Paulo (Latam compliance)
            ]
          }
        }
      }
    ]
  })

  type = "SERVICE_CONTROL_POLICY"
}

# --------------------------------------------------------------------------------------------------
# POLÍTICA: REQUERIR CIFRADO EN S3
# --------------------------------------------------------------------------------------------------
resource "aws_organizations_policy" "require_s3_encryption" {
  name        = "RequireS3Encryption"
  description = "Niega creación de buckets sin cifrado server-side"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyUnencryptedObjectUploads"
        Effect   = "Deny"
        Action   = "s3:PutObject"
        Resource = "arn:aws:s3:::*/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = [
              "AES256",
              "aws:kms"
            ]
          }
        }
      }
    ]
  })

  type = "SERVICE_CONTROL_POLICY"
}

# --------------------------------------------------------------------------------------------------
# POLÍTICA: PREVENIR SALIDA DE LA ORGANIZACIÓN
# --------------------------------------------------------------------------------------------------
resource "aws_organizations_policy" "prevent_leave_organization" {
  count = var.prevent_leaving_organization ? 1 : 0

  name        = "PreventLeaveOrganization"
  description = "Previene que cuentas abandonen la organización"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyLeaveOrganization"
        Effect   = "Deny"
        Action   = "organizations:LeaveOrganization"
        Resource = "*"
      }
    ]
  })

  type = "SERVICE_CONTROL_POLICY"
}

# --------------------------------------------------------------------------------------------------
# OUTPUTS
# --------------------------------------------------------------------------------------------------
output "policy_ids" {
  description = "IDs de las políticas SCP creadas"
  value = {
    prevent_critical_deletion = aws_organizations_policy.prevent_critical_resource_deletion.id
    deny_root                 = var.enable_deny_root_actions ? aws_organizations_policy.deny_root_account[0].id : null
    require_mfa               = var.require_mfa_for_sensitive_actions ? aws_organizations_policy.require_mfa[0].id : null
    deny_regions              = aws_organizations_policy.deny_unapproved_regions.id
    require_s3_encryption     = aws_organizations_policy.require_s3_encryption.id
    prevent_leave_org         = var.prevent_leaving_organization ? aws_organizations_policy.prevent_leave_organization[0].id : null
  }
}
