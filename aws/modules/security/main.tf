# ==================================================================================================
# MÓDULO DE SEGURIDAD AWS
# ==================================================================================================
# Autor: Ronny Ortiz
# Propósito: Implementar políticas de seguridad y detección de amenazas a nivel de cuenta
# Componentes: IAM Password Policy, AWS GuardDuty
# ==================================================================================================

# --------------------------------------------------------------------------------------------------
# POLÍTICA DE CONTRASEÑAS IAM ESTRICTA
# --------------------------------------------------------------------------------------------------
# Implementa requisitos de complejidad para cumplir con NIST 800-63B y CIS AWS Foundations
# - Longitud mínima: 14 caracteres (supera el mínimo de 12 de PCI-DSS)
# - Rotación cada 90 días para reducir ventana de exposición
# - Prevención de reutilización de últimas 24 contraseñas
resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 14   # NIST recomienda mínimo 12-14 chars
  require_lowercase_characters   = true # Requiere al menos una minúscula
  require_numbers                = true # Requiere al menos un número
  require_uppercase_characters   = true # Requiere al menos una mayúscula
  require_symbols                = true # Requiere al menos un símbolo especial
  allow_users_to_change_password = true # Permite auto-servicio de cambio
  password_reuse_prevention      = 24   # Previene reuso de últimas 24 contraseñas
  max_password_age               = 90   # Expiración cada 90 días (trimestral)
}

# --------------------------------------------------------------------------------------------------
# AWS GUARDDUTY - DETECCIÓN DE AMENAZAS
# --------------------------------------------------------------------------------------------------
# Servicio de detección de amenazas basado en machine learning.
# Analiza logs de CloudTrail, VPC Flow Logs, y DNS logs para identificar:
# - Actividad inusual de API
# - Comunicación con IPs maliciosas conocidas
# - Comportamiento de instancias comprometidas
# - Exfiltración de datos vía S3
resource "aws_guardduty_detector" "main" {
  enable = true # Habilita monitoreo continuo

  datasources {
    # Monitoreo de actividad en S3 (accesos inusuales, descargas masivas)
    s3_logs {
      enable = true
    }
    # Auditoría de logs de Kubernetes/EKS (detección de pods maliciosos)
    kubernetes {
      audit_logs {
        enable = true
      }
    }
  }
}
