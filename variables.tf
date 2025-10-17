variable "resource_group_name" {
  description = "Name of the Azure Resource Group for DR environment"
  type        = string
  default     = "dr-analytics-platform-rg"
}

variable "location" {
  description = "Azure region for the DR deployment"
  type        = string
  default     = "East US 2"
}

variable "project_name" {
  description = "Name of the project used for resource naming"
  type        = string
  default     = "dranalytics"
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  # No default - force user to provide actual domain
}

variable "admin_email" {
  description = "Administrator email for alerts and notifications"
  type        = string
}

variable "synapse_admin_username" {
  description = "Admin username for Synapse Analytics"
  type        = string
  default     = "synadmin"
}

variable "synapse_admin_password" {
  description = "Admin password for Synapse Analytics"
  type        = string
  sensitive   = true
}

variable "sql_admin_username" {
  description = "Admin username for SQL Server"
  type        = string
  default     = "sqladmin"
}

variable "sql_admin_password" {
  description = "Admin password for SQL Server"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags to be applied to all resources"
  type        = map(string)
  default = {
    Environment = "DR"
    Project     = "Analytics Platform"
    ManagedBy   = "Terraform"
    Purpose     = "Disaster Recovery"
  }
}

variable "shiny_app_port" {
  description = "Port for Shiny applications"
  type        = number
  default     = 3838
}

variable "rstudio_port" {
  description = "Port for RStudio Server"
  type        = number
  default     = 8787
}

variable "enable_backup" {
  description = "Enable backup for storage accounts and databases"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30
}

variable "allowed_ip_ranges" {
  description = "List of IP ranges allowed to access the infrastructure"
  type        = list(string)
  default     = []  # No access by default - force user to specify allowed IPs
}

# Cost Management Variables
variable "monthly_budget_amount" {
  description = "Monthly budget limit for the entire resource group (USD)"
  type        = number
  default     = 3000
}

variable "compute_budget_amount" {
  description = "Monthly budget limit for compute resources (USD)"
  type        = number
  default     = 1500
}

variable "cost_center" {
  description = "Cost center for billing and tracking"
  type        = string
  default     = "IT-Infrastructure"
}

variable "business_unit" {
  description = "Business unit for cost allocation"
  type        = string
  default     = "Analytics"
}

variable "storage_alert_threshold_gb" {
  description = "Storage capacity threshold in GB for cost alerts"
  type        = number
  default     = 800
}

variable "enable_cost_automation" {
  description = "Enable automated cost optimization features"
  type        = bool
  default     = false
}

variable "cost_webhook_url" {
  description = "Webhook URL for cost alert notifications (optional)"
  type        = string
  default     = ""
}