terraform {
  required_version = ">= 1.5.0"
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
  name                = "${var.name_prefix}_vnet"
  address_space       = [var.vnet_cidr]
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  tags = var.tags
}

resource "azurerm_subnet" "workload" {
  for_each = var.subnet_configs

  name                 = "${var.name_prefix}_subnet_${each.key}"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_resource_group.main.name
  address_prefixes     = [each.value.cidr]
}

moved {
  from = azurerm_subnet.linux
  to   = azurerm_subnet.workload["linux"]
}

moved {
  from = azurerm_subnet.windows
  to   = azurerm_subnet.workload["windows"]
}

resource "azurerm_public_ip" "linux" {
  count = var.linux_count

  name                = "${var.name_prefix}_pip_linux_${count.index + 1}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags
}
