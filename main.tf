# Resource Group for DR environment
resource "azurerm_resource_group" "dr_rg" {
  name     = var.resource_group_name
  location = var.location

  tags = var.tags
}

# Random ID for unique resource naming
resource "random_id" "suffix" {
  byte_length = 4
}

# Azure Container Registry (equivalent to AWS ECR)
resource "azurerm_container_registry" "acr" {
  name                = "${var.project_name}acr${random_id.suffix.hex}"
  resource_group_name = azurerm_resource_group.dr_rg.name
  location            = azurerm_resource_group.dr_rg.location
  sku                 = "Standard"
  admin_enabled       = false

  tags = var.tags
}

# Key Vault for certificates and secrets (equivalent to AWS Certificate Manager)
resource "azurerm_key_vault" "kv" {
  name                = "${var.project_name}-kv-${random_id.suffix.hex}"
  location            = azurerm_resource_group.dr_rg.location
  resource_group_name = azurerm_resource_group.dr_rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # Security hardening
  public_network_access_enabled = false
  purge_protection_enabled      = true
  soft_delete_retention_days    = 90

  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
    virtual_network_subnet_ids = [
      azurerm_subnet.private_subnet_a.id,
      azurerm_subnet.private_subnet_b.id,
      azurerm_subnet.gateway_subnet.id
    ]
    ip_rules = var.allowed_ip_ranges
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    certificate_permissions = [
      "Create",
      "Delete",
      "Get",
      "Import",
      "List",
      "Update",
    ]

    key_permissions = [
      "Create",
      "Get",
      "List",
      "Update",
      "Delete",
    ]

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
    ]
  }

  tags = var.tags
}

# Data source for current Azure client configuration
data "azurerm_client_config" "current" {}