# Cost Management and Budgets

# Budget for the entire resource group
resource "azurerm_consumption_budget_resource_group" "monthly_budget" {
  name              = "${var.project_name}-monthly-budget"
  resource_group_id = azurerm_resource_group.dr_rg.id

  amount     = var.monthly_budget_amount
  time_grain = "Monthly"

  time_period {
    start_date = formatdate("YYYY-MM-01'T'00:00:00'Z'", timestamp())
    end_date   = formatdate("YYYY-MM-01'T'00:00:00'Z'", timeadd(timestamp(), "8760h")) # 1 year
  }

  filter {
    dimension {
      name     = "ResourceGroupName"
      operator = "In"
      values   = [azurerm_resource_group.dr_rg.name]
    }
  }

  # Alert at 80% of budget
  notification {
    enabled   = true
    threshold = 80
    operator  = "GreaterThan"

    contact_emails = [var.admin_email]
  }

  # Alert at 90% of budget
  notification {
    enabled   = true
    threshold = 90
    operator  = "GreaterThan"

    contact_emails = [var.admin_email]
  }

  # Critical alert at 100% of budget
  notification {
    enabled   = true
    threshold = 100
    operator  = "GreaterThan"

    contact_emails = [var.admin_email]
  }
}

# Budget specifically for compute resources
resource "azurerm_consumption_budget_resource_group" "compute_budget" {
  name              = "${var.project_name}-compute-budget"
  resource_group_id = azurerm_resource_group.dr_rg.id

  amount     = var.compute_budget_amount
  time_grain = "Monthly"

  time_period {
    start_date = formatdate("YYYY-MM-01'T'00:00:00'Z'", timestamp())
    end_date   = formatdate("YYYY-MM-01'T'00:00:00'Z'", timeadd(timestamp(), "8760h"))
  }

  filter {
    dimension {
      name     = "ResourceGroupName"
      operator = "In"
      values   = [azurerm_resource_group.dr_rg.name]
    }

    dimension {
      name     = "ServiceName"
      operator = "In"
      values   = [
        "Container Instances",
        "Application Gateway",
        "Azure Synapse Analytics"
      ]
    }
  }

  notification {
    enabled   = true
    threshold = 85
    operator  = "GreaterThan"

    contact_emails = [var.admin_email]
  }
}

# Enhanced resource tagging for cost tracking
locals {
  cost_tags = merge(var.tags, {
    CostCenter   = var.cost_center
    BusinessUnit = var.business_unit
    Application  = "R-Analytics-DR"
    Criticality  = "High"
    Backup       = var.enable_backup ? "Required" : "Optional"
  })
}

# Cost analysis action group for automated responses
resource "azurerm_monitor_action_group" "cost_alerts" {
  name                = "${var.project_name}-cost-alerts"
  resource_group_name = azurerm_resource_group.dr_rg.name
  short_name          = "CostAlert"

  email_receiver {
    name          = "cost-admin"
    email_address = var.admin_email
  }

  # Webhook for automated cost optimization (optional)
  webhook_receiver {
    name        = "cost-webhook"
    service_uri = var.cost_webhook_url
  }

  tags = local.cost_tags
}

# Alert rule for high storage costs
resource "azurerm_monitor_metric_alert" "high_storage_cost" {
  name                = "${var.project_name}-high-storage-cost"
  resource_group_name = azurerm_resource_group.dr_rg.name
  scopes              = [azurerm_storage_account.main_storage.id]
  description         = "Alert when storage costs are high"
  enabled             = true
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Storage/storageAccounts"
    metric_name      = "UsedCapacity"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.storage_alert_threshold_gb * 1073741824 # Convert GB to bytes
  }

  action {
    action_group_id = azurerm_monitor_action_group.cost_alerts.id
  }

  tags = local.cost_tags
}

# Automation runbook for cost optimization (optional)
resource "azurerm_automation_account" "cost_optimization" {
  count               = var.enable_cost_automation ? 1 : 0
  name                = "${var.project_name}-cost-automation"
  location            = azurerm_resource_group.dr_rg.location
  resource_group_name = azurerm_resource_group.dr_rg.name
  sku_name            = "Basic"

  tags = local.cost_tags
}

# Runbook to pause Synapse when not in use
resource "azurerm_automation_runbook" "pause_synapse" {
  count                   = var.enable_cost_automation ? 1 : 0
  name                    = "PauseSynapsePool"
  location                = azurerm_resource_group.dr_rg.location
  resource_group_name     = azurerm_resource_group.dr_rg.name
  automation_account_name = azurerm_automation_account.cost_optimization[0].name
  log_verbose             = "true"
  log_progress            = "true"
  description            = "Automatically pause Synapse SQL pools during off hours"
  runbook_type           = "PowerShell"

  content = <<CONTENT
param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory=$true)]
    [string]$WorkspaceName,

    [Parameter(Mandatory=$true)]
    [string]$PoolName
)

# Authenticate using managed identity
Connect-AzAccount -Identity

# Check current time (adjust timezone as needed)
$currentHour = (Get-Date).Hour

# Pause pool during off hours (6 PM to 6 AM)
if ($currentHour -ge 18 -or $currentHour -lt 6) {
    Write-Output "Off hours detected. Pausing Synapse pool: $PoolName"
    Suspend-AzSynapseSqlPool -ResourceGroupName $ResourceGroupName -WorkspaceName $WorkspaceName -SqlPoolName $PoolName
    Write-Output "Pool paused successfully"
} else {
    Write-Output "Business hours detected. Pool remains active"
}
CONTENT

  tags = local.cost_tags
}

# Schedule to run the cost optimization runbook
resource "azurerm_automation_schedule" "pause_synapse_schedule" {
  count                   = var.enable_cost_automation ? 1 : 0
  name                    = "PauseSynapseSchedule"
  resource_group_name     = azurerm_resource_group.dr_rg.name
  automation_account_name = azurerm_automation_account.cost_optimization[0].name
  frequency               = "Hour"
  interval                = 1
  description            = "Check every hour if Synapse pool should be paused"
}

# Link schedule to runbook
resource "azurerm_automation_job_schedule" "pause_synapse_job" {
  count                   = var.enable_cost_automation ? 1 : 0
  resource_group_name     = azurerm_resource_group.dr_rg.name
  automation_account_name = azurerm_automation_account.cost_optimization[0].name
  schedule_name           = azurerm_automation_schedule.pause_synapse_schedule[0].name
  runbook_name            = azurerm_automation_runbook.pause_synapse[0].name

  parameters = {
    ResourceGroupName = azurerm_resource_group.dr_rg.name
    WorkspaceName     = azurerm_synapse_workspace.main_synapse.name
    PoolName          = azurerm_synapse_spark_pool.main_spark_pool.name
  }
}