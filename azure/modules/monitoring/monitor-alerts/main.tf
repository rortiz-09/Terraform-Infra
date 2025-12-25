# ==================================================================================================
# MÓDULO: AZURE MONITOR ALERTS - OBSERVABILIDAD
# ==================================================================================================
# Autor: Ronny Ortiz
# Propósito: Alertas proactivas para monitoreo de recursos Azure
# WAF Pillar: Operational Excellence - Monitoring and alerting
# ==================================================================================================

variable "resource_group_name" {
  description = "Resource group para las alertas"
  type        = string
}

variable "location" {
  description = "Ubicación de Azure"
  type        = string
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

variable "email_recipients" {
  description = "Emails para recibir alertas"
  type        = list(string)
  default     = []
}

variable "log_analytics_workspace_id" {
  description = "ID del Log Analytics Workspace para queries"
  type        = string
  default     = null
}

# --------------------------------------------------------------------------------------------------
# ACTION GROUP PARA NOTIFICACIONES
# --------------------------------------------------------------------------------------------------
resource "azurerm_monitor_action_group" "critical" {
  name                = "ag-${var.project_name}-${var.environment}-critical"
  resource_group_name = var.resource_group_name
  short_name          = "CritAlert"

  dynamic "email_receiver" {
    for_each = var.email_recipients

    content {
      name          = "email-${email_receiver.key}"
      email_address = email_receiver.value
    }
  }

  # Webhook para integración con herramientas (PagerDuty, Slack, etc.)
  # webhook_receiver {
  #   name        = "webhook-oncall"
  #   service_uri = "https://hooks.slack.com/services/..."
  # }

  tags = {
    Purpose = "Critical Alerts Notifications"
  }
}

# --------------------------------------------------------------------------------------------------
# ALERTA: VM CPU ALTA
# --------------------------------------------------------------------------------------------------
resource "azurerm_monitor_metric_alert" "vm_high_cpu" {
  name                = "alert-${var.project_name}-vm-high-cpu"
  resource_group_name = var.resource_group_name
  scopes              = ["/subscriptions/${data.azurerm_subscription.current.subscription_id}"]
  description         = "VM CPU utilization above threshold"
  severity            = 2 # 0=Critical, 1=Error, 2=Warning, 3=Informational
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.environment == "prod" ? 80 : 90
  }

  action {
    action_group_id = azurerm_monitor_action_group.critical.id
  }

  tags = {
    Severity = "High"
  }
}

# --------------------------------------------------------------------------------------------------
# ALERTA: STORAGE ACCOUNT CAPACIDAD
# --------------------------------------------------------------------------------------------------
resource "azurerm_monitor_metric_alert" "storage_capacity" {
  name                = "alert-${var.project_name}-storage-capacity"
  resource_group_name = var.resource_group_name
  scopes              = ["/subscriptions/${data.azurerm_subscription.current.subscription_id}"]
  description         = "Storage account nearing capacity"
  severity            = 2
  frequency           = "PT1H"
  window_size         = "PT6H"

  criteria {
    metric_namespace = "Microsoft.Storage/storageAccounts"
    metric_name      = "UsedCapacity"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 85 # Porcentaje
  }

  action {
    action_group_id = azurerm_monitor_action_group.critical.id
  }
}

# --------------------------------------------------------------------------------------------------
# ALERTA: SQL DATABASE DTU ALTA
# --------------------------------------------------------------------------------------------------
resource "azurerm_monitor_metric_alert" "sql_high_dtu" {
  name                = "alert-${var.project_name}-sql-high-dtu"
  resource_group_name = var.resource_group_name
  scopes              = ["/subscriptions/${data.azurerm_subscription.current.subscription_id}"]
  description         = "SQL Database DTU utilization high"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Sql/servers/databases"
    metric_name      = "dtu_consumption_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.critical.id
  }

  tags = {
    Severity = "High"
  }
}

# --------------------------------------------------------------------------------------------------
# ALERTA: APP SERVICE ERRORES HTTP
# --------------------------------------------------------------------------------------------------
resource "azurerm_monitor_metric_alert" "appservice_http_errors" {
  name                = "alert-${var.project_name}-app-http-errors"
  resource_group_name = var.resource_group_name
  scopes              = ["/subscriptions/${data.azurerm_subscription.current.subscription_id}"]
  description         = "High rate of HTTP 5xx errors"
  severity            = 1 # Error level
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "Http5xx"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 10
  }

  action {
    action_group_id = azurerm_monitor_action_group.critical.id
  }

  tags = {
    Severity = "Critical"
  }
}

# --------------------------------------------------------------------------------------------------
# ALERTA: KEY VAULT ACCESO DENEGADO
# --------------------------------------------------------------------------------------------------
resource "azurerm_monitor_metric_alert" "keyvault_access_denied" {
  name                = "alert-${var.project_name}-kv-denied"
  resource_group_name = var.resource_group_name
  scopes              = ["/subscriptions/${data.azurerm_subscription.current.subscription_id}"]
  description         = "Unauthorized Key Vault access attempts"
  severity            = 1
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.KeyVault/vaults"
    metric_name      = "ServiceApiResult"
    aggregation      = "Count"
    operator         = "GreaterThan"
    threshold        = 5

    dimension {
      name     = "StatusCode"
      operator = "Include"
      values   = ["403"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.critical.id
  }

  tags = {
    Severity = "Security"
  }
}

# --------------------------------------------------------------------------------------------------
# LOG ANALYTICS QUERY ALERT (si workspace disponible)
# --------------------------------------------------------------------------------------------------
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "failed_logins" {
  count = var.log_analytics_workspace_id != null ? 1 : 0

  name                = "alert-${var.project_name}-failed-logins"
  resource_group_name = var.resource_group_name
  location            = var.location
  scopes              = [var.log_analytics_workspace_id]
  description         = "Multiple failed login attempts detected"
  severity            = 2
  enabled             = true

  evaluation_frequency = "PT5M"
  window_duration      = "PT15M"

  criteria {
    query = <<-QUERY
      SigninLogs
      | where ResultType != "0"
      | summarize FailedLogins = count() by UserPrincipalName, bin(TimeGenerated, 5m)
      | where FailedLogins > 5
    QUERY

    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"
  }

  action {
    action_groups = [azurerm_monitor_action_group.critical.id]
  }

  tags = {
    Severity = "Security"
    Type     = "Query-based"
  }
}

# --------------------------------------------------------------------------------------------------
# DATA SOURCE
# --------------------------------------------------------------------------------------------------
data "azurerm_subscription" "current" {}

# --------------------------------------------------------------------------------------------------
# OUTPUTS
# --------------------------------------------------------------------------------------------------
output "action_group_id" {
  description = "ID del Action Group para alerts"
  value       = azurerm_monitor_action_group.critical.id
}

output "alert_names" {
  description = "Nombres de todas las alertas creadas"
  value = {
    vm_cpu              = azurerm_monitor_metric_alert.vm_high_cpu.name
    storage_capacity    = azurerm_monitor_metric_alert.storage_capacity.name
    sql_dtu             = azurerm_monitor_metric_alert.sql_high_dtu.name
    app_http_errors     = azurerm_monitor_metric_alert.appservice_http_errors.name
    keyvault_denied     = azurerm_monitor_metric_alert.keyvault_access_denied.name
    failed_logins_query = var.log_analytics_workspace_id != null ? azurerm_monitor_scheduled_query_rules_alert_v2.failed_logins[0].name : null
  }
}
