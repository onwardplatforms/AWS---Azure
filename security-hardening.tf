# Additional Security Hardening - Production Requirements

# Customer-managed encryption key for storage
resource "azurerm_key_vault_key" "storage_encryption_key" {
  name         = "storage-encryption-key"
  key_vault_id = azurerm_key_vault.kv.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]

  depends_on = [azurerm_key_vault.kv]
}

# DDoS Protection
resource "azurerm_network_ddos_protection_plan" "ddos" {
  name                = "${var.project_name}-ddos-plan"
  location            = azurerm_resource_group.dr_rg.location
  resource_group_name = azurerm_resource_group.dr_rg.name

  tags = var.tags
}

# Private endpoint for storage account
resource "azurerm_private_endpoint" "storage_blob_pe" {
  name                = "${var.project_name}-storage-blob-pe"
  location            = azurerm_resource_group.dr_rg.location
  resource_group_name = azurerm_resource_group.dr_rg.name
  subnet_id           = azurerm_subnet.private_subnet_a.id

  private_service_connection {
    name                           = "${var.project_name}-storage-blob-psc"
    private_connection_resource_id = azurerm_storage_account.main_storage.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  tags = var.tags
}

resource "azurerm_private_endpoint" "storage_file_pe" {
  name                = "${var.project_name}-storage-file-pe"
  location            = azurerm_resource_group.dr_rg.location
  resource_group_name = azurerm_resource_group.dr_rg.name
  subnet_id           = azurerm_subnet.private_subnet_a.id

  private_service_connection {
    name                           = "${var.project_name}-storage-file-psc"
    private_connection_resource_id = azurerm_storage_account.main_storage.id
    is_manual_connection           = false
    subresource_names              = ["file"]
  }

  tags = var.tags
}

# Private endpoint for Key Vault
resource "azurerm_private_endpoint" "kv_private_endpoint" {
  name                = "${var.project_name}-kv-pe"
  location            = azurerm_resource_group.dr_rg.location
  resource_group_name = azurerm_resource_group.dr_rg.name
  subnet_id           = azurerm_subnet.private_subnet_a.id

  private_service_connection {
    name                           = "${var.project_name}-kv-psc"
    private_connection_resource_id = azurerm_key_vault.kv.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  tags = var.tags
}

# Private endpoint for Container Registry
resource "azurerm_private_endpoint" "acr_private_endpoint" {
  name                = "${var.project_name}-acr-pe"
  location            = azurerm_resource_group.dr_rg.location
  resource_group_name = azurerm_resource_group.dr_rg.name
  subnet_id           = azurerm_subnet.private_subnet_a.id

  private_service_connection {
    name                           = "${var.project_name}-acr-psc"
    private_connection_resource_id = azurerm_container_registry.acr.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }

  tags = var.tags
}

# SQL Database TDE with customer-managed key
resource "azurerm_key_vault_key" "sql_tde_key" {
  name         = "sql-tde-key"
  key_vault_id = azurerm_key_vault.kv.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]

  depends_on = [azurerm_key_vault.kv]
}

# SQL Server security policies
resource "azurerm_mssql_server_security_alert_policy" "sql_security_alert" {
  resource_group_name = azurerm_resource_group.dr_rg.name
  server_name         = azurerm_mssql_server.main_sql_server.name
  state               = "Enabled"

  email_addresses      = [var.admin_email]
  email_account_admins = true
  retention_days       = 90

  depends_on = [azurerm_mssql_server.main_sql_server]
}

resource "azurerm_mssql_server_vulnerability_assessment" "sql_va" {
  server_security_alert_policy_id = azurerm_mssql_server_security_alert_policy.sql_security_alert.id
  storage_container_path          = "${azurerm_storage_account.main_storage.primary_blob_endpoint}vulnerability-assessment/"
  storage_account_access_key      = azurerm_storage_account.main_storage.primary_access_key

  recurring_scans {
    enabled                   = true
    email_subscription_admins = true
    emails                    = [var.admin_email]
  }
}

# Azure Policy assignment for security baseline
resource "azurerm_resource_group_policy_assignment" "security_baseline" {
  name                 = "azure-security-baseline"
  resource_group_id    = azurerm_resource_group.dr_rg.id
  policy_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/1f3afdf9-d0c9-4c3d-847f-89da613e70a8"

  parameters = jsonencode({
    "effect" : {
      "value" : "AuditIfNotExists"
    }
  })
}

# Azure Security Center pricing
resource "azurerm_security_center_subscription_pricing" "vm_pricing" {
  tier          = "Standard"
  resource_type = "VirtualMachines"
}

resource "azurerm_security_center_subscription_pricing" "storage_pricing" {
  tier          = "Standard"
  resource_type = "StorageAccounts"
}

resource "azurerm_security_center_subscription_pricing" "sql_pricing" {
  tier          = "Standard"
  resource_type = "SqlServers"
}

resource "azurerm_security_center_subscription_pricing" "containers_pricing" {
  tier          = "Standard"
  resource_type = "ContainerRegistry"
}