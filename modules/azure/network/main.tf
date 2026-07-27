terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.name_prefix}_vnet"
  address_space       = [var.vnet_cidr]
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_subnet" "workload" {
  for_each = var.subnet_configs

  name                 = "${var.name_prefix}_subnet_${each.key}"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = var.resource_group_name
  address_prefixes     = [each.value.cidr]
}

resource "azurerm_public_ip" "linux" {
  count = var.instances.linux.count

  name                = "${var.name_prefix}_pip_linux_${count.index + 1}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  # domain_name_label   = replace(lower("${var.name_prefix}-linux-${count.index + 1}"), "_", "-")

  tags = var.tags
}

resource "azurerm_public_ip" "windows" {
  count = var.instances.windows.count

  name                = "${var.name_prefix}_pip_windows_${count.index + 1}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  # domain_name_label   = replace(lower("${var.name_prefix}-windows-${count.index + 1}"), "_", "-")

  tags = var.tags
}


resource "azurerm_network_interface" "linux" {
  count = var.instances.linux.count

  name                = "${var.name_prefix}_nic_linux_${count.index + 1}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.workload["linux"].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.linux[count.index].id
  }

  tags = var.tags
}

resource "azurerm_network_interface_security_group_association" "linux" {
  count = var.instances.linux.count

  network_interface_id      = azurerm_network_interface.linux[count.index].id
  network_security_group_id = var.network_security_group_ids.linux
}

resource "azurerm_network_interface" "windows" {
  count = var.instances.windows.count

  name                = "${var.name_prefix}_nic_windows_${count.index + 1}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.workload["windows"].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.windows[count.index].id
  }

  tags = var.tags
}

resource "azurerm_network_interface_security_group_association" "windows" {
  count = var.instances.windows.count

  network_interface_id      = azurerm_network_interface.windows[count.index].id
  network_security_group_id = var.network_security_group_ids.windows
}