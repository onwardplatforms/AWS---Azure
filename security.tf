# Network Security Group for Private Subnets
resource "azurerm_network_security_group" "private_nsg" {
  name                = "${var.project_name}-private-nsg"
  location            = azurerm_resource_group.dr_rg.location
  resource_group_name = azurerm_resource_group.dr_rg.name

  # Allow inbound from Application Gateway subnet
  security_rule {
    name                       = "AllowAppGateway"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443", "8080", "3838"]
    source_address_prefix      = "10.0.3.0/24"
    destination_address_prefix = "*"
  }

  # Allow internal VNet traffic
  security_rule {
    name                       = "AllowVNetInBound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  # Allow NFS traffic for Azure Files
  security_rule {
    name                       = "AllowNFS"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "2049"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # Deny all other inbound traffic
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# Network Security Group for Public Subnets
resource "azurerm_network_security_group" "public_nsg" {
  name                = "${var.project_name}-public-nsg"
  location            = azurerm_resource_group.dr_rg.location
  resource_group_name = azurerm_resource_group.dr_rg.name

  # Allow HTTP/HTTPS inbound
  security_rule {
    name                       = "AllowHTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow SFTP
  security_rule {
    name                       = "AllowSFTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# Associate NSGs with subnets
resource "azurerm_subnet_network_security_group_association" "private_nsg_assoc_a" {
  subnet_id                 = azurerm_subnet.private_subnet_a.id
  network_security_group_id = azurerm_network_security_group.private_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "private_nsg_assoc_b" {
  subnet_id                 = azurerm_subnet.private_subnet_b.id
  network_security_group_id = azurerm_network_security_group.private_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "public_nsg_assoc_a" {
  subnet_id                 = azurerm_subnet.public_subnet_a.id
  network_security_group_id = azurerm_network_security_group.public_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "public_nsg_assoc_b" {
  subnet_id                 = azurerm_subnet.public_subnet_b.id
  network_security_group_id = azurerm_network_security_group.public_nsg.id
}

# Azure Application Gateway with WAF (equivalent to AWS WAF + ELB)
resource "azurerm_application_gateway" "main_appgw" {
  name                = "${var.project_name}-appgw"
  resource_group_name = azurerm_resource_group.dr_rg.name
  location            = azurerm_resource_group.dr_rg.location

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  waf_configuration {
    enabled          = true
    firewall_mode    = "Prevention"
    rule_set_type    = "OWASP"
    rule_set_version = "3.2"
  }

  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = azurerm_subnet.gateway_subnet.id
  }

  frontend_port {
    name = "port_80"
    port = 80
  }

  frontend_port {
    name = "port_443"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "appGwPublicFrontendIp"
    public_ip_address_id = azurerm_public_ip.app_gateway_ip.id
  }

  # Backend pools for Shiny and R Studio applications
  backend_address_pool {
    name = "shiny-backend-pool"
  }

  backend_address_pool {
    name = "rstudio-backend-pool"
  }

  backend_http_settings {
    name                  = "shiny-backend-settings"
    cookie_based_affinity = "Disabled"
    path                  = "/path1/"
    port                  = 3838
    protocol              = "Http"
    request_timeout       = 60
  }

  backend_http_settings {
    name                  = "rstudio-backend-settings"
    cookie_based_affinity = "Disabled"
    path                  = "/path1/"
    port                  = 8787
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = "shiny-listener"
    frontend_ip_configuration_name = "appGwPublicFrontendIp"
    frontend_port_name             = "port_80"
    protocol                       = "Http"
  }

  http_listener {
    name                           = "rstudio-listener"
    frontend_ip_configuration_name = "appGwPublicFrontendIp"
    frontend_port_name             = "port_80"
    protocol                       = "Http"
    host_name                      = "rstudio.${var.domain_name}"
  }

  request_routing_rule {
    name                       = "shiny-routing-rule"
    priority                   = 9
    rule_type                  = "Basic"
    http_listener_name         = "shiny-listener"
    backend_address_pool_name  = "shiny-backend-pool"
    backend_http_settings_name = "shiny-backend-settings"
  }

  request_routing_rule {
    name                       = "rstudio-routing-rule"
    priority                   = 10
    rule_type                  = "Basic"
    http_listener_name         = "rstudio-listener"
    backend_address_pool_name  = "rstudio-backend-pool"
    backend_http_settings_name = "rstudio-backend-settings"
  }

  tags = var.tags
}