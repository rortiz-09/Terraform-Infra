# ==================================================================================================
# MÓDULO: CLOUDWATCH ALARMS - OBSERVABILIDAD
# ==================================================================================================
# Autor: Ronny Ortiz
# Propósito: Alarmas proactivas para monitoreo de salud y performance
# WAF Pillar: Operational Excellence - Monitor and respond to events
# ==================================================================================================

variable "project_name" {
  description = "Nombre del proyecto para naming"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN del SNS topic para notificaciones (opcional)"
  type        = string
  default     = null
}

variable "email_endpoints" {
  description = "Emails para recibir alertas críticas"
  type        = list(string)
  default     = []
}

# --------------------------------------------------------------------------------------------------
# SNS TOPIC PARA ALERTAS
# --------------------------------------------------------------------------------------------------
resource "aws_sns_topic" "alerts" {
  count = var.sns_topic_arn == null ? 1 : 0

  name              = "${var.project_name}-${var.environment}-alerts"
  display_name      = "Critical Alerts - ${var.project_name}"
  kms_master_key_id = "alias/aws/sns" # Cifrado en reposo

  tags = {
    Purpose = "CloudWatch Alarms Notifications"
  }
}

# Subscripciones de email
resource "aws_sns_topic_subscription" "email" {
  count = length(var.email_endpoints)

  topic_arn = local.topic_arn
  protocol  = "email"
  endpoint  = var.email_endpoints[count.index]
}

locals {
  topic_arn = var.sns_topic_arn != null ? var.sns_topic_arn : aws_sns_topic.alerts[0].arn
}

# --------------------------------------------------------------------------------------------------
# ALARMA: CPU ALTA EN EC2
# --------------------------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300 # 5 minutos
  statistic           = "Average"
  threshold           = var.environment == "prod" ? 80 : 90
  alarm_description   = "CPU utilization above ${var.environment == "prod" ? 80 : 90}%"
  treat_missing_data  = "notBreaching"

  alarm_actions = [local.topic_arn]
  ok_actions    = [local.topic_arn]

  tags = {
    Severity = "High"
  }
}

# --------------------------------------------------------------------------------------------------
# ALARMA: ERRORES 5XX EN ALB
# --------------------------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "${var.project_name}-${var.environment}-alb-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "High rate of 5XX errors from targets"
  treat_missing_data  = "notBreaching"

  alarm_actions = [local.topic_arn]

  tags = {
    Severity = "Critical"
  }
}

# --------------------------------------------------------------------------------------------------
# ALARMA: UNHEALTHY TARGETS EN ALB
# --------------------------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "unhealthy_targets" {
  alarm_name          = "${var.project_name}-${var.environment}-unhealthy-targets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "One or more targets are unhealthy"
  treat_missing_data  = "notBreaching"

  alarm_actions = [local.topic_arn]

  tags = {
    Severity = "High"
  }
}

# --------------------------------------------------------------------------------------------------
# ALARMA: RDS CPU ALTA
# --------------------------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "rds_high_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-rds-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 75
  alarm_description   = "RDS CPU utilization above 75%"
  treat_missing_data  = "notBreaching"

  alarm_actions = [local.topic_arn]

  tags = {
    Severity = "Medium"
  }
}

# --------------------------------------------------------------------------------------------------
# ALARMA: RDS BAJO ESPACIO EN DISCO
# --------------------------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "rds_low_storage" {
  alarm_name          = "${var.project_name}-${var.environment}-rds-low-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 10737418240 # 10 GB
  alarm_description   = "RDS free storage below 10 GB"
  treat_missing_data  = "notBreaching"

  alarm_actions = [local.topic_arn]

  tags = {
    Severity = "High"
  }
}

# --------------------------------------------------------------------------------------------------
# ALARMA: LAMBDA ERRORES
# --------------------------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.project_name}-${var.environment}-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Lambda function errors above threshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [local.topic_arn]

  tags = {
    Severity = "High"
  }
}

# --------------------------------------------------------------------------------------------------
# ALARMA: LAMBDA THROTTLES
# --------------------------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  alarm_name          = "${var.project_name}-${var.environment}-lambda-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Lambda function being throttled"
  treat_missing_data  = "notBreaching"

  alarm_actions = [local.topic_arn]

  tags = {
    Severity = "Medium"
  }
}

# --------------------------------------------------------------------------------------------------
# COMPOSITE ALARM: SISTEMA CRÍTICO
# --------------------------------------------------------------------------------------------------
resource "aws_cloudwatch_composite_alarm" "system_critical" {
  alarm_name        = "${var.project_name}-${var.environment}-system-critical"
  alarm_description = "Multiple critical alarms firing"
  actions_enabled   = true
  alarm_actions     = [local.topic_arn]

  alarm_rule = join(" OR ", [
    "ALARM(${aws_cloudwatch_metric_alarm.alb_5xx_errors.alarm_name})",
    "ALARM(${aws_cloudwatch_metric_alarm.unhealthy_targets.alarm_name})",
    "ALARM(${aws_cloudwatch_metric_alarm.rds_low_storage.alarm_name})"
  ])

  tags = {
    Severity = "Critical"
    Type     = "Composite"
  }
}

# --------------------------------------------------------------------------------------------------
# OUTPUTS
# --------------------------------------------------------------------------------------------------
output "sns_topic_arn" {
  description = "ARN del SNS topic para alerts"
  value       = local.topic_arn
}

output "alarm_names" {
  description = "Nombres de todas las alarmas creadas"
  value = {
    high_cpu         = aws_cloudwatch_metric_alarm.high_cpu.alarm_name
    alb_5xx          = aws_cloudwatch_metric_alarm.alb_5xx_errors.alarm_name
    unhealthy        = aws_cloudwatch_metric_alarm.unhealthy_targets.alarm_name
    rds_cpu          = aws_cloudwatch_metric_alarm.rds_high_cpu.alarm_name
    rds_storage      = aws_cloudwatch_metric_alarm.rds_low_storage.alarm_name
    lambda_errors    = aws_cloudwatch_metric_alarm.lambda_errors.alarm_name
    lambda_throttles = aws_cloudwatch_metric_alarm.lambda_throttles.alarm_name
    composite        = aws_cloudwatch_composite_alarm.system_critical.alarm_name
  }
}
