# Network Profiles for Container Groups
resource "azurerm_network_profile" "container_profile_a" {
  name                = "${var.project_name}-container-profile-a"
  location            = azurerm_resource_group.dr_rg.location
  resource_group_name = azurerm_resource_group.dr_rg.name

  container_network_interface {
    name = "container-nic-a"

    ip_configuration {
      name      = "internal"
      subnet_id = azurerm_subnet.private_subnet_a.id
    }
  }

  tags = var.tags
}

resource "azurerm_network_profile" "container_profile_b" {
  name                = "${var.project_name}-container-profile-b"
  location            = azurerm_resource_group.dr_rg.location
  resource_group_name = azurerm_resource_group.dr_rg.name

  container_network_interface {
    name = "container-nic-b"

    ip_configuration {
      name      = "internal"
      subnet_id = azurerm_subnet.private_subnet_b.id
    }
  }

  tags = var.tags
}

# Container Groups for Shiny Applications in Zone A (equivalent to AWS Fargate)
resource "azurerm_container_group" "shiny_containers_a" {
  name                = "${var.project_name}-shiny-a"
  location            = azurerm_resource_group.dr_rg.location
  resource_group_name = azurerm_resource_group.dr_rg.name
  ip_address_type     = "Private"
  network_profile_id  = azurerm_network_profile.container_profile_a.id
  os_type             = "Linux"

  container {
    name   = "shiny-app"
    image  = "rocker/shiny:latest"
    cpu    = "1"
    memory = "2"

    ports {
      port     = 3838
      protocol = "TCP"
    }

    environment_variables = {
      "ENVIRONMENT" = "DR"
      "ZONE"        = "A"
    }

    volume {
      name                 = "shiny-data"
      mount_path           = "/srv/shiny-server"
      storage_account_name = azurerm_storage_account.main_storage.name
      storage_account_key  = azurerm_storage_account.main_storage.primary_access_key
      share_name           = azurerm_storage_share.shiny_share.name
    }
  }

  tags = var.tags
}

# Container Groups for Shiny Applications in Zone B
resource "azurerm_container_group" "shiny_containers_b" {
  name                = "${var.project_name}-shiny-b"
  location            = azurerm_resource_group.dr_rg.location
  resource_group_name = azurerm_resource_group.dr_rg.name
  ip_address_type     = "Private"
  network_profile_id  = azurerm_network_profile.container_profile_b.id
  os_type             = "Linux"

  container {
    name   = "shiny-app"
    image  = "rocker/shiny:latest"
    cpu    = "1"
    memory = "2"

    ports {
      port     = 3838
      protocol = "TCP"
    }

    environment_variables = {
      "ENVIRONMENT" = "DR"
      "ZONE"        = "B"
    }

    volume {
      name                 = "shiny-data"
      mount_path           = "/srv/shiny-server"
      storage_account_name = azurerm_storage_account.main_storage.name
      storage_account_key  = azurerm_storage_account.main_storage.primary_access_key
      share_name           = azurerm_storage_share.shiny_share.name
    }
  }

  tags = var.tags
}

# Container Groups for R Studio in Zone A
resource "azurerm_container_group" "rstudio_containers_a" {
  name                = "${var.project_name}-rstudio-a"
  location            = azurerm_resource_group.dr_rg.location
  resource_group_name = azurerm_resource_group.dr_rg.name
  ip_address_type     = "Private"
  network_profile_id  = azurerm_network_profile.container_profile_a.id
  os_type             = "Linux"

  container {
    name   = "rstudio-server"
    image  = "rocker/rstudio:latest"
    cpu    = "2"
    memory = "4"

    ports {
      port     = 8787
      protocol = "TCP"
    }

    environment_variables = {
      "ENVIRONMENT" = "DR"
      "ZONE"        = "A"
      "USER"        = "rstudio"
      "PASSWORD"    = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault.kv.vault_uri}secrets/rstudio-password/)"
      "ROOT"        = "true"
    }

    volume {
      name                 = "rstudio-data"
      mount_path           = "/home/rstudio"
      storage_account_name = azurerm_storage_account.main_storage.name
      storage_account_key  = azurerm_storage_account.main_storage.primary_access_key
      share_name           = azurerm_storage_share.rstudio_share.name
    }
  }

  tags = var.tags
}

# Container Groups for R Studio in Zone B
resource "azurerm_container_group" "rstudio_containers_b" {
  name                = "${var.project_name}-rstudio-b"
  location            = azurerm_resource_group.dr_rg.location
  resource_group_name = azurerm_resource_group.dr_rg.name
  ip_address_type     = "Private"
  network_profile_id  = azurerm_network_profile.container_profile_b.id
  os_type             = "Linux"

  container {
    name   = "rstudio-server"
    image  = "rocker/rstudio:latest"
    cpu    = "2"
    memory = "4"

    ports {
      port     = 8787
      protocol = "TCP"
    }

    environment_variables = {
      "ENVIRONMENT" = "DR"
      "ZONE"        = "B"
      "USER"        = "rstudio"
      "PASSWORD"    = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault.kv.vault_uri}secrets/rstudio-password/)"
      "ROOT"        = "true"
    }

    volume {
      name                 = "rstudio-data"
      mount_path           = "/home/rstudio"
      storage_account_name = azurerm_storage_account.main_storage.name
      storage_account_key  = azurerm_storage_account.main_storage.primary_access_key
      share_name           = azurerm_storage_share.rstudio_share.name
    }
  }

  tags = var.tags
}

# Azure Data Factory (equivalent to AWS DataSync)
resource "azurerm_data_factory" "main_adf" {
  name                = "${var.project_name}-adf-${random_id.suffix.hex}"
  location            = azurerm_resource_group.dr_rg.location
  resource_group_name = azurerm_resource_group.dr_rg.name

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# SFTP Server using Azure Container Instances (equivalent to AWS Transfer Family)
resource "azurerm_container_group" "sftp_server" {
  name                = "${var.project_name}-sftp"
  location            = azurerm_resource_group.dr_rg.location
  resource_group_name = azurerm_resource_group.dr_rg.name
  ip_address_type     = "Private"
  network_profile_id  = azurerm_network_profile.container_profile_a.id
  os_type             = "Linux"

  container {
    name   = "sftp-server"
    image  = "atmoz/sftp:latest"
    cpu    = "1"
    memory = "1"

    ports {
      port     = 22
      protocol = "TCP"
    }

    environment_variables = {
      "SFTP_USERS" = "sftpuser:@Microsoft.KeyVault(SecretUri=${azurerm_key_vault.kv.vault_uri}secrets/sftp-password/):1001:100:upload"
    }

    volume {
      name                 = "sftp-data"
      mount_path           = "/home/sftpuser/upload"
      storage_account_name = azurerm_storage_account.main_storage.name
      storage_account_key  = azurerm_storage_account.main_storage.primary_access_key
      share_name           = azurerm_storage_share.upload_share.name
    }
  }

  tags = var.tags
}