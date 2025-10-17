output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.dr_rg.name
}

output "virtual_network_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main_vnet.id
}

output "application_gateway_public_ip" {
  description = "Public IP address of the Application Gateway"
  value       = azurerm_public_ip.app_gateway_ip.ip_address
}

output "application_gateway_fqdn" {
  description = "FQDN of the Application Gateway"
  value       = azurerm_public_ip.app_gateway_ip.fqdn
}

output "sftp_server_ip" {
  description = "Public IP address of the SFTP server"
  value       = azurerm_container_group.sftp_server.ip_address
}

output "storage_account_name" {
  description = "Name of the main storage account"
  value       = azurerm_storage_account.main_storage.name
}

output "storage_account_primary_blob_endpoint" {
  description = "Primary blob endpoint of the storage account"
  value       = azurerm_storage_account.main_storage.primary_blob_endpoint
}

output "container_registry_name" {
  description = "Name of the Azure Container Registry"
  value       = azurerm_container_registry.acr.name
}

output "container_registry_login_server" {
  description = "Login server for the Azure Container Registry"
  value       = azurerm_container_registry.acr.login_server
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.kv.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.kv.vault_uri
}

output "synapse_workspace_name" {
  description = "Name of the Synapse workspace"
  value       = azurerm_synapse_workspace.main_synapse.name
}

output "synapse_workspace_web_url" {
  description = "Web URL of the Synapse workspace"
  value       = "https://${azurerm_synapse_workspace.main_synapse.name}.dev.azuresynapse.net"
}

output "sql_server_fqdn" {
  description = "Fully qualified domain name of the SQL server"
  value       = azurerm_mssql_server.main_sql_server.fully_qualified_domain_name
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main_workspace.workspace_id
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation key for Application Insights"
  value       = azurerm_application_insights.app_insights.instrumentation_key
  sensitive   = true
}

output "dns_zone_name_servers" {
  description = "Name servers for the DNS zone"
  value       = azurerm_dns_zone.main_dns_zone.name_servers
}

output "shiny_container_ips" {
  description = "Private IP addresses of Shiny containers"
  value = {
    zone_a = azurerm_container_group.shiny_containers_a.ip_address
    zone_b = azurerm_container_group.shiny_containers_b.ip_address
  }
}

output "rstudio_container_ips" {
  description = "Private IP addresses of RStudio containers"
  value = {
    zone_a = azurerm_container_group.rstudio_containers_a.ip_address
    zone_b = azurerm_container_group.rstudio_containers_b.ip_address
  }
}

output "data_factory_name" {
  description = "Name of the Azure Data Factory"
  value       = azurerm_data_factory.main_adf.name
}

output "nat_gateway_public_ips" {
  description = "Public IP addresses of NAT gateways"
  value = {
    zone_a = azurerm_public_ip.nat_gateway_ip_a.ip_address
    zone_b = azurerm_public_ip.nat_gateway_ip_b.ip_address
  }
}

# Connection strings and access information
output "storage_connection_string" {
  description = "Connection string for the storage account"
  value       = azurerm_storage_account.main_storage.primary_connection_string
  sensitive   = true
}

output "container_registry_admin_username" {
  description = "Admin username for the container registry"
  value       = azurerm_container_registry.acr.admin_username
}

output "container_registry_admin_password" {
  description = "Admin password for the container registry"
  value       = azurerm_container_registry.acr.admin_password
  sensitive   = true
}

# Cost Management Outputs
output "monthly_budget_id" {
  description = "ID of the monthly budget for cost tracking"
  value       = azurerm_consumption_budget_resource_group.monthly_budget.id
}

output "cost_management_dashboard_url" {
  description = "URL to view cost analysis in Azure portal"
  value       = "https://portal.azure.com/#blade/Microsoft_Azure_CostManagement/Menu/costanalysis/scope/%2Fsubscriptions%2F${data.azurerm_client_config.current.subscription_id}%2FresourceGroups%2F${azurerm_resource_group.dr_rg.name}"
}

output "estimated_monthly_costs" {
  description = "Estimated monthly cost breakdown"
  value = {
    compute_low    = "$850"
    compute_high   = "$1,800"
    storage_low    = "$400"
    storage_high   = "$1,200"
    networking     = "$300-650"
    security       = "$200-450"
    total_low      = "$1,850"
    total_high     = "$4,300"
    budget_set     = "$${var.monthly_budget_amount}"
  }
}

output "cost_optimization_recommendations" {
  description = "Key cost optimization opportunities"
  value = {
    reserved_instances = "Save 38% with 1-year reservations on SQL/Synapse"
    auto_pause         = "Enable auto-pause on Synapse for 40-60% savings"
    storage_tiers      = "Use Cool tier for infrequently accessed data"
    right_sizing       = "Monitor and resize over-provisioned resources"
    spot_instances     = "Use spot pricing for dev/test workloads"
  }
}