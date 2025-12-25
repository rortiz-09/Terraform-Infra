# ==================================================================================================
# MÓDULO DE GOBERNANZA AWS - AWS CONFIG RULES
# ==================================================================================================
# Autor: Ronny Ortiz
# Propósito: Implementar reglas de cumplimiento automático mediante AWS Config
# Componentes: Reglas de configuración para SSH y cifrado de volúmenes
# ==================================================================================================

# --------------------------------------------------------------------------------------------------
# REGLA: PROHIBIR SSH PÚBLICO
# --------------------------------------------------------------------------------------------------
# Verifica que ningún Security Group permita SSH (puerto 22) desde 0.0.0.0/0
# Cumplimiento: CIS AWS Foundations Benchmark 4.1, 4.2
# Acción: Marca como NO_COMPLIANT (no remedia automáticamente para evitar disrupción)
resource "aws_config_config_rule" "ssh_restricted" {
  name = "restricted-ssh"

  source {
    owner             = "AWS"                   # Regla administrada por AWS
    source_identifier = "INCOMING_SSH_DISABLED" # ID de la regla pre-configurada
  }

  # Nota: Requiere AWS Config Recorder habilitado previamente
  # Evalúa configuración cada vez que cambia un Security Group
}

# --------------------------------------------------------------------------------------------------
# REGLA: CIFRADO DE VOLÚMENES EBS POR DEFECTO
# --------------------------------------------------------------------------------------------------
# Verifica que el cifrado de EBS esté habilitado por defecto en la cuenta
# Cumplimiento: PCI-DSS Requisito 3.4, HIPAA § 164.312(a)(2)(iv)
# Beneficio: Protege datos en reposo automáticamente sin intervención manual
resource "aws_config_config_rule" "encrypted_volumes" {
  name = "encrypted-volumes"

  source {
    owner             = "AWS"
    source_identifier = "EC2_EBS_ENCRYPTION_BY_DEFAULT" # Verifica setting a nivel cuenta
  }

  # Habilitar cifrado por defecto con:
  # aws ec2 enable-ebs-encryption-by-default --region us-east-1
}
