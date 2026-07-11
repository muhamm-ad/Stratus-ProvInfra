terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = var.tags
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.name_prefix}-vnet"
  address_space       = [var.vnet_cidr]
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  tags = var.tags
}

resource "azurerm_subnet" "linux" {
  name                 = "${var.name_prefix}-subnet-linux"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_resource_group.main.name
  address_prefixes     = [var.subnet_configs.linux.cidr]
}

resource "azurerm_subnet" "windows" {
  name                 = "${var.name_prefix}-subnet-windows"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_resource_group.main.name
  address_prefixes     = [var.subnet_configs.windows.cidr]
}

resource "azurerm_public_ip" "linux" {
  count = var.linux_count

  name                = "${var.name_prefix}-pip-linux-${count.index + 1}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags
}
