# Log Analytics Workspace (equivalent to AWS CloudWatch Logs)
resource "azurerm_log_analytics_workspace" "main_workspace" {
  name                = "${var.project_name}-log-analytics"
  location            = azurerm_resource_group.dr_rg.location
  resource_group_name = azurerm_resource_group.dr_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = var.tags
}

# Application Insights for application monitoring
resource "azurerm_application_insights" "app_insights" {
  name                = "${var.project_name}-appinsights"
  location            = azurerm_resource_group.dr_rg.location
  resource_group_name = azurerm_resource_group.dr_rg.name
  workspace_id        = azurerm_log_analytics_workspace.main_workspace.id
  application_type    = "web"

  tags = var.tags
}

# Azure Monitor Action Group for alerts
resource "azurerm_monitor_action_group" "main_action_group" {
  name                = "${var.project_name}-alerts"
  resource_group_name = azurerm_resource_group.dr_rg.name
  short_name          = "AlertsAG"

  email_receiver {
    name          = "admin-email"
    email_address = var.admin_email
  }

  tags = var.tags
}

# Monitor Alert Rules
resource "azurerm_monitor_metric_alert" "container_cpu_alert" {
  name                = "${var.project_name}-container-cpu-alert"
  resource_group_name = azurerm_resource_group.dr_rg.name
  scopes = [
    azurerm_container_group.shiny_containers_a.id,
    azurerm_container_group.shiny_containers_b.id,
    azurerm_container_group.rstudio_containers_a.id,
    azurerm_container_group.rstudio_containers_b.id
  ]
  description = "Alert when container CPU usage is high"

  criteria {
    metric_namespace = "Microsoft.ContainerInstance/containerGroups"
    metric_name      = "CpuUsage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80

    dimension {
      name     = "containerName"
      operator = "Include"
      values   = ["*"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.main_action_group.id
  }

  tags = var.tags
}

resource "azurerm_monitor_metric_alert" "storage_capacity_alert" {
  name                = "${var.project_name}-storage-capacity-alert"
  resource_group_name = azurerm_resource_group.dr_rg.name
  scopes              = [azurerm_storage_account.main_storage.id]
  description         = "Alert when storage capacity usage is high"

  criteria {
    metric_namespace = "Microsoft.Storage/storageAccounts"
    metric_name      = "UsedCapacity"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 85000000000 # 85 GB in bytes
  }

  action {
    action_group_id = azurerm_monitor_action_group.main_action_group.id
  }

  tags = var.tags
}

# Azure DNS Zone (equivalent to AWS Route 53)
resource "azurerm_dns_zone" "main_dns_zone" {
  name                = var.domain_name
  resource_group_name = azurerm_resource_group.dr_rg.name

  tags = var.tags
}

# DNS A Record for main application
resource "azurerm_dns_a_record" "main_app" {
  name                = "@"
  zone_name           = azurerm_dns_zone.main_dns_zone.name
  resource_group_name = azurerm_resource_group.dr_rg.name
  ttl                 = 300
  records             = [azurerm_public_ip.app_gateway_ip.ip_address]

  tags = var.tags
}

# DNS A Record for RStudio
resource "azurerm_dns_a_record" "rstudio" {
  name                = "rstudio"
  zone_name           = azurerm_dns_zone.main_dns_zone.name
  resource_group_name = azurerm_resource_group.dr_rg.name
  ttl                 = 300
  records             = [azurerm_public_ip.app_gateway_ip.ip_address]

  tags = var.tags
}

# DNS A Record for SFTP
resource "azurerm_dns_a_record" "sftp" {
  name                = "sftp"
  zone_name           = azurerm_dns_zone.main_dns_zone.name
  resource_group_name = azurerm_resource_group.dr_rg.name
  ttl                 = 300
  records             = [azurerm_container_group.sftp_server.ip_address]

  tags = var.tags
}

# Azure Security Center (equivalent to AWS GuardDuty)
resource "azurerm_security_center_subscription_pricing" "security_center" {
  tier          = "Standard"
  resource_type = "VirtualMachines"
}

# Diagnostic settings for Application Gateway
resource "azurerm_monitor_diagnostic_setting" "app_gateway_diagnostics" {
  name                       = "app-gateway-diagnostics"
  target_resource_id         = azurerm_application_gateway.main_appgw.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main_workspace.id

  enabled_log {
    category = "ApplicationGatewayAccessLog"
  }

  enabled_log {
    category = "ApplicationGatewayPerformanceLog"
  }

  enabled_log {
    category = "ApplicationGatewayFirewallLog"
  }

  metric {
    category = "AllMetrics"
  }
}

# Diagnostic settings for Storage Account
resource "azurerm_monitor_diagnostic_setting" "storage_diagnostics" {
  name                       = "storage-diagnostics"
  target_resource_id         = azurerm_storage_account.main_storage.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main_workspace.id

  metric {
    category = "Capacity"
  }

  metric {
    category = "Transaction"
  }
}