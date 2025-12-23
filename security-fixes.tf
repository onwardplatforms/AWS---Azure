# Critical Security Fixes - Apply These Immediately

# 1. Generate secure passwords in Key Vault instead of hardcoding
resource "azurerm_key_vault_secret" "sftp_password" {
  name         = "sftp-password"
  value        = random_password.sftp_password.result
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [azurerm_key_vault.kv]
}

resource "azurerm_key_vault_secret" "rstudio_password" {
  name         = "rstudio-password"
  value        = random_password.rstudio_password.result
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [azurerm_key_vault.kv]
}

resource "random_password" "sftp_password" {
  length  = 16
  special = true
}

resource "random_password" "rstudio_password" {
  length  = 16
  special = true
}

# 2. User-assigned identity for containers instead of storage keys
resource "azurerm_user_assigned_identity" "container_identity" {
  location            = azurerm_resource_group.dr_rg.location
  name                = "${var.project_name}-container-identity"
  resource_group_name = azurerm_resource_group.dr_rg.name

  tags = var.tags
}

# 3. RBAC roles instead of access keys
resource "azurerm_role_assignment" "container_storage_contributor" {
  scope                = azurerm_storage_account.main_storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.container_identity.principal_id
}

resource "azurerm_role_assignment" "container_file_contributor" {
  scope                = azurerm_storage_account.main_storage.id
  role_definition_name = "Storage File Data SMB Share Contributor"
  principal_id         = azurerm_user_assigned_identity.container_identity.principal_id
}

# 4. Network security improvements
resource "azurerm_network_security_rule" "restrict_ssh" {
  name                        = "RestrictSSH"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefixes     = var.allowed_ip_ranges # Not 0.0.0.0/0
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.dr_rg.name
  network_security_group_name = azurerm_network_security_group.public_nsg.name
}

# 5. SSL Certificate for Application Gateway
resource "azurerm_key_vault_certificate" "app_gateway_cert" {
  name         = "app-gateway-ssl"
  key_vault_id = azurerm_key_vault.kv.id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 30
      }
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      key_usage = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyAgreement",
        "keyCertSign",
        "keyEncipherment",
      ]

      subject            = "CN=${var.domain_name}"
      validity_in_months = 12

      subject_alternative_names {
        dns_names = [
          var.domain_name,
          "*.${var.domain_name}"
        ]
      }
    }
  }

  depends_on = [azurerm_key_vault.kv]
}

# 6. Advanced Threat Protection
resource "azurerm_advanced_threat_protection" "storage_atp" {
  target_resource_id = azurerm_storage_account.main_storage.id
  enabled            = true
}

# 7. Resource locks to prevent deletion
resource "azurerm_management_lock" "resource_group_lock" {
  name       = "rg-lock"
  scope      = azurerm_resource_group.dr_rg.id
  lock_level = "CanNotDelete"
  notes      = "Prevent accidental deletion of DR resources"
}