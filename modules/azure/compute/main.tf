terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

resource "azurerm_network_interface" "linux" {
  count = try(var.linux_instances.count, 0)

  name                = "${var.name_prefix}_nic_linux_${count.index + 1}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = try(var.linux_instances.subnet_id, null)
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = try(var.linux_instances.public_ip_ids[count.index], null)
  }

  tags = var.tags
}

resource "azurerm_network_interface_security_group_association" "linux" {
  count = try(var.linux_instances.count, 0)

  network_interface_id      = azurerm_network_interface.linux[count.index].id
  network_security_group_id = try(var.linux_instances.network_security_group_id, null)
}

resource "azurerm_linux_virtual_machine" "main" {
  count = try(var.linux_instances.count, 0)

  name                = "${var.name_prefix}_linux_${count.index + 1}"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = try(var.linux_instances.vm_size, null)
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.linux[count.index].id
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file(pathexpand(var.ssh_public_key_path))
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 32
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "24_04-lts-gen2"
    version   = "latest"
  }

  tags = merge(
    var.tags,
    { Name = "${var.name_prefix}_linux_${count.index + 1}" }
  )
}

resource "azurerm_network_interface" "windows" {
  count = try(var.windows_instances.count, 0)

  name                = "${var.name_prefix}_nic_windows_${count.index + 1}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = try(var.windows_instances.subnet_id, null)
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

resource "azurerm_network_interface_security_group_association" "windows" {
  count = try(var.windows_instances.count, 0)

  network_interface_id      = azurerm_network_interface.windows[count.index].id
  network_security_group_id = try(var.windows_instances.network_security_group_id, null)
}

resource "azurerm_windows_virtual_machine" "main" {
  count = try(var.windows_instances.count, 0)

  name                = "${var.name_prefix}_windows_${count.index + 1}"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = try(var.windows_instances.vm_size, null)
  admin_username      = try(var.windows_instances.admin_username, null)
  admin_password      = try(var.windows_instances.admin_password, null)

  network_interface_ids = [
    azurerm_network_interface.windows[count.index].id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 32
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  tags = merge(
    var.tags,
    { Name = "${var.name_prefix}_windows_${count.index + 1}" }
  )
}
