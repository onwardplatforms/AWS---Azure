# Storage Account (equivalent to AWS S3)
resource "azurerm_storage_account" "main_storage" {
  name                     = "${var.project_name}storage${random_id.suffix.hex}"
  resource_group_name      = azurerm_resource_group.dr_rg.name
  location                 = azurerm_resource_group.dr_rg.location
  account_tier             = "Standard"
  account_replication_type = "ZRS" # Zone-redundant storage for high availability
  account_kind             = "StorageV2"

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 30
    }

    container_delete_retention_policy {
      days = 30
    }
  }

  # Security hardening: Restrict network access
  min_tls_version                   = "TLS1_2"
  https_traffic_only_enabled        = true
  allow_nested_items_to_be_public   = false
  infrastructure_encryption_enabled = true

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
    virtual_network_subnet_ids = [
      azurerm_subnet.private_subnet_a.id,
      azurerm_subnet.private_subnet_b.id,
      azurerm_subnet.gateway_subnet.id
    ]
    ip_rules = var.allowed_ip_ranges
  }

  tags = var.tags
}

# Storage Containers (equivalent to S3 buckets)
resource "azurerm_storage_container" "data_ingestion" {
  name                  = "data-ingestion"
  storage_account_name  = azurerm_storage_account.main_storage.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "processed_data" {
  name                  = "processed-data"
  storage_account_name  = azurerm_storage_account.main_storage.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "application_logs" {
  name                  = "application-logs"
  storage_account_name  = azurerm_storage_account.main_storage.name
  container_access_type = "private"
}

# Azure Files shares (equivalent to AWS EFS)
resource "azurerm_storage_share" "shiny_share" {
  name                 = "shiny-apps"
  storage_account_name = azurerm_storage_account.main_storage.name
  quota                = 100 # GB

  acl {
    id = "shared-access"

    access_policy {
      permissions = "rwdl"
      start       = "2024-01-01T00:00:00Z"
      expiry      = "2025-12-31T23:59:59Z"
    }
  }
}

resource "azurerm_storage_share" "rstudio_share" {
  name                 = "rstudio-data"
  storage_account_name = azurerm_storage_account.main_storage.name
  quota                = 200 # GB

  acl {
    id = "shared-access"

    access_policy {
      permissions = "rwdl"
      start       = "2024-01-01T00:00:00Z"
      expiry      = "2025-12-31T23:59:59Z"
    }
  }
}

resource "azurerm_storage_share" "upload_share" {
  name                 = "sftp-uploads"
  storage_account_name = azurerm_storage_account.main_storage.name
  quota                = 500 # GB

  acl {
    id = "upload-access"

    access_policy {
      permissions = "rwdl"
      start       = "2024-01-01T00:00:00Z"
      expiry      = "2025-12-31T23:59:59Z"
    }
  }
}

# Data Lake Gen2 for Synapse (created first)
resource "azurerm_storage_data_lake_gen2_filesystem" "synapse_fs" {
  name               = "synapse-data"
  storage_account_id = azurerm_storage_account.main_storage.id
}

# Azure Synapse Analytics (equivalent to AWS Athena)
resource "azurerm_synapse_workspace" "main_synapse" {
  name                                 = "${var.project_name}-synapse-${random_id.suffix.hex}"
  resource_group_name                  = azurerm_resource_group.dr_rg.name
  location                             = azurerm_resource_group.dr_rg.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.synapse_fs.id
  sql_administrator_login              = var.synapse_admin_username
  sql_administrator_login_password     = var.synapse_admin_password

  # Security hardening
  managed_virtual_network_enabled = true
  public_network_access_enabled   = false
  managed_resource_group_name     = "${var.project_name}-synapse-managed-rg"

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}


# Role assignment for Synapse to access storage
resource "azurerm_role_assignment" "synapse_storage_contributor" {
  scope                = azurerm_storage_account.main_storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_synapse_workspace.main_synapse.identity[0].principal_id
}

# Synapse Spark Pool for data processing
resource "azurerm_synapse_spark_pool" "main_spark_pool" {
  name                 = "sparkpool01"
  synapse_workspace_id = azurerm_synapse_workspace.main_synapse.id
  node_size_family     = "MemoryOptimized"
  node_size            = "Small"
  cache_size           = 100

  auto_scale {
    max_node_count = 10
    min_node_count = 3
  }

  auto_pause {
    delay_in_minutes = 15
  }

  tags = var.tags
}

# Azure SQL Database for metadata and configuration
resource "azurerm_mssql_server" "main_sql_server" {
  name                         = "${var.project_name}-sql-${random_id.suffix.hex}"
  resource_group_name          = azurerm_resource_group.dr_rg.name
  location                     = azurerm_resource_group.dr_rg.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password

  # Security hardening
  public_network_access_enabled = false
  minimum_tls_version           = "1.2"

  azuread_administrator {
    login_username = "AzureAD Admin"
    object_id      = data.azurerm_client_config.current.object_id
  }

  tags = var.tags
}

resource "azurerm_mssql_database" "metadata_db" {
  name      = "metadata-db"
  server_id = azurerm_mssql_server.main_sql_server.id
  sku_name  = "S1"

  tags = var.tags
}

# Private Endpoint for SQL Server
resource "azurerm_private_endpoint" "sql_private_endpoint" {
  name                = "${var.project_name}-sql-pe"
  location            = azurerm_resource_group.dr_rg.location
  resource_group_name = azurerm_resource_group.dr_rg.name
  subnet_id           = azurerm_subnet.private_subnet_a.id

  private_service_connection {
    name                           = "${var.project_name}-sql-psc"
    private_connection_resource_id = azurerm_mssql_server.main_sql_server.id
    is_manual_connection           = false
    subresource_names              = ["sqlServer"]
  }

  tags = var.tags
}