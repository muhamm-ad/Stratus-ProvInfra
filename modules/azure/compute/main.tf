terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

locals {
  userdata_dir = "${path.module}/../../shared/userdata"
}

resource "azurerm_linux_virtual_machine" "main" {
  count = try(var.linux_instances.count, 0)

  name                = "${var.name_prefix}_linux_${count.index + 1}"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.linux_instances.vm_size
  network_interface_ids = [
    var.linux_instances.network_interface_ids[count.index]
  ]
  os_disk {
    caching              = var.linux_instances.disk.caching
    storage_account_type = var.linux_instances.disk.type
    disk_size_gb         = var.linux_instances.disk.size_gb
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts" # "0001-com-ubuntu-server-jammy"
    sku       = "server"
    version   = "latest"
  }

  admin_username = var.linux_instances.username
  # admin_ssh_key { # FIXME: add support for SSH key
  #   username   = var.linux_instances.username
  #   public_key = var.linux_instances.key_name
  # }

  custom_data = base64encode(templatefile("${local.userdata_dir}/linux-userdata.yaml", {
    username = var.linux_instances.username
    extra    = coalesce(try(var.linux_instances.user_data, null), "")
  }))
  lifecycle {
    ignore_changes = [custom_data]
  }

  tags = merge(
    var.tags,
    { Name = "${var.name_prefix}_linux_${count.index + 1}" }
  )
}


resource "azurerm_windows_virtual_machine" "main" {
  count = try(var.windows_instances.count, 0)

  name                = "${var.name_prefix}_windows_${count.index + 1}"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.windows_instances.vm_size
  admin_username      = var.windows_instances.username
  admin_password      = var.windows_instances.password_to_change
  network_interface_ids = [
    var.windows_instances.network_interface_ids[count.index]
  ]
  os_disk {
    caching              = var.windows_instances.disk.caching
    storage_account_type = var.windows_instances.disk.type
    disk_size_gb         = var.windows_instances.disk.size_gb
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

resource "azurerm_virtual_machine_run_command" "windows_bootstrap" {
  count = try(var.windows_instances.count, 0)

  name               = "bootstrap"
  location           = var.location
  virtual_machine_id = azurerm_windows_virtual_machine.main[count.index].id

  source {
    # Admin user is already created by azurerm_windows_virtual_machine;
    # skip user creation and only install OpenSSH + run extra script.
    script = templatefile("${local.userdata_dir}/win-userdata.ps1", {
      username           = ""
      password_to_change = ""
      extra              = coalesce(try(var.windows_instances.user_data, null), "")
    })
  }
}
