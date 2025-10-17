# Virtual Network (equivalent to AWS VPC)
resource "azurerm_virtual_network" "main_vnet" {
  name                = "${var.project_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.dr_rg.location
  resource_group_name = azurerm_resource_group.dr_rg.name

  tags = var.tags
}

# Public Subnet for Zone A
resource "azurerm_subnet" "public_subnet_a" {
  name                 = "public-subnet-a"
  resource_group_name  = azurerm_resource_group.dr_rg.name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Public Subnet for Zone B
resource "azurerm_subnet" "public_subnet_b" {
  name                 = "public-subnet-b"
  resource_group_name  = azurerm_resource_group.dr_rg.name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Private Subnet for Zone A
resource "azurerm_subnet" "private_subnet_a" {
  name                 = "private-subnet-a"
  resource_group_name  = azurerm_resource_group.dr_rg.name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = ["10.0.11.0/24"]

  delegation {
    name = "container-delegation"
    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# Private Subnet for Zone B
resource "azurerm_subnet" "private_subnet_b" {
  name                 = "private-subnet-b"
  resource_group_name  = azurerm_resource_group.dr_rg.name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = ["10.0.12.0/24"]

  delegation {
    name = "container-delegation"
    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# Subnet for Application Gateway
resource "azurerm_subnet" "gateway_subnet" {
  name                 = "gateway-subnet"
  resource_group_name  = azurerm_resource_group.dr_rg.name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

# Public IPs for NAT Gateways
resource "azurerm_public_ip" "nat_gateway_ip_a" {
  name                = "${var.project_name}-nat-ip-a"
  location            = azurerm_resource_group.dr_rg.location
  resource_group_name = azurerm_resource_group.dr_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1"]

  tags = var.tags
}

resource "azurerm_public_ip" "nat_gateway_ip_b" {
  name                = "${var.project_name}-nat-ip-b"
  location            = azurerm_resource_group.dr_rg.location
  resource_group_name = azurerm_resource_group.dr_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["2"]

  tags = var.tags
}

# NAT Gateway for Zone A (equivalent to AWS NAT Gateway)
resource "azurerm_nat_gateway" "nat_gateway_a" {
  name                = "${var.project_name}-nat-gateway-a"
  location            = azurerm_resource_group.dr_rg.location
  resource_group_name = azurerm_resource_group.dr_rg.name
  zones               = ["1"]

  tags = var.tags
}

# NAT Gateway for Zone B
resource "azurerm_nat_gateway" "nat_gateway_b" {
  name                = "${var.project_name}-nat-gateway-b"
  location            = azurerm_resource_group.dr_rg.location
  resource_group_name = azurerm_resource_group.dr_rg.name
  zones               = ["2"]

  tags = var.tags
}

# Associate NAT Gateway with Public IPs
resource "azurerm_nat_gateway_public_ip_association" "nat_gateway_ip_assoc_a" {
  nat_gateway_id       = azurerm_nat_gateway.nat_gateway_a.id
  public_ip_address_id = azurerm_public_ip.nat_gateway_ip_a.id
}

resource "azurerm_nat_gateway_public_ip_association" "nat_gateway_ip_assoc_b" {
  nat_gateway_id       = azurerm_nat_gateway.nat_gateway_b.id
  public_ip_address_id = azurerm_public_ip.nat_gateway_ip_b.id
}

# Associate NAT Gateway with Private Subnets
resource "azurerm_subnet_nat_gateway_association" "nat_gateway_assoc_a" {
  subnet_id      = azurerm_subnet.private_subnet_a.id
  nat_gateway_id = azurerm_nat_gateway.nat_gateway_a.id
}

resource "azurerm_subnet_nat_gateway_association" "nat_gateway_assoc_b" {
  subnet_id      = azurerm_subnet.private_subnet_b.id
  nat_gateway_id = azurerm_nat_gateway.nat_gateway_b.id
}

# Public IP for Application Gateway
resource "azurerm_public_ip" "app_gateway_ip" {
  name                = "${var.project_name}-appgw-ip"
  location            = azurerm_resource_group.dr_rg.location
  resource_group_name = azurerm_resource_group.dr_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags
}