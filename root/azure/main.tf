locals {
  name_prefix = "${var.environment}_${var.project_name}"

  azure_config = var.cloud_providers.azure

  enable_linux   = var.instances.linux != null
  enable_windows = var.instances.windows != null

  linux_config   = var.instances.linux
  windows_config = var.instances.windows

  common_tags = merge(
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform"
      Owner       = var.owner_email
    },
    var.additional_tags
  )

  username = regex("^([^@]+)", var.owner_email)[0]
}

resource "time_static" "creation_timestamp" {}

resource "time_static" "modification_timestamp" {
  triggers = {
    always_recreate = timestamp()
  }
}

resource "azurerm_resource_group" "main" {
  name     = "${local.name_prefix}_rg"
  location = local.azure_config.location
}


module "nsg" {
  source = "../../modules/azure/nsg"

  name_prefix         = local.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = local.azure_config.location

  tags = merge(local.common_tags, {
    CreatedAt  = time_static.creation_timestamp.rfc3339
    ModifiedAt = time_static.modification_timestamp.rfc3339
  })
}

module "network" {
  source     = "../../modules/azure/network"
  depends_on = [azurerm_resource_group.main]

  name_prefix         = local.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = local.azure_config.location
  network_security_group_ids = {
    linux   = module.nsg.nsg_id
    windows = module.nsg.nsg_id
  }
  vnet_cidr = local.azure_config.vnet_cidr

  instances = merge(
    local.enable_linux ? {
      linux = {
        count = local.linux_config.count
      }
    } : {},
    local.enable_windows ? {
      windows = {
        count = local.windows_config.count
      }
    } : {}
  )

  subnet_configs = merge(
    local.enable_linux ? {
      linux = {
        cidr = local.linux_config.cidr.azure
      }
    } : {},
    local.enable_windows ? {
      windows = {
        cidr = local.windows_config.cidr.azure
      }
    } : {}
  )

  tags = merge(local.common_tags, {
    CreatedAt  = time_static.creation_timestamp.rfc3339
    ModifiedAt = time_static.modification_timestamp.rfc3339
  })
}

module "compute" {
  source = "../../modules/azure/compute"

  name_prefix         = local.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = local.azure_config.location

  linux_instances = local.enable_linux ? {
    count                 = local.linux_config.count
    vm_size               = local.linux_config.instance_type.azure
    subnet_id             = module.network.subnet_ids.linux
    network_interface_ids = module.network.network_interface_ids.linux
    user_data             = local.linux_config.script
    username              = local.linux_config.username != "" ? local.linux_config.username : local.username
    disk                  = local.linux_config.disk.azure
  } : null

  windows_instances = local.enable_windows ? {
    count                 = local.windows_config.count
    vm_size               = local.windows_config.instance_type.azure
    subnet_id             = module.network.subnet_ids.windows
    network_interface_ids = module.network.network_interface_ids.windows
    user_data             = local.windows_config.script
    username              = local.windows_config.username != "" ? local.windows_config.username : local.username
    password_to_change    = local.windows_config.password_to_change != "" ? local.windows_config.password_to_change : "Stratus@123"
    disk                  = local.windows_config.disk.azure
  } : null

  tags = merge(local.common_tags, {
    CreatedAt  = time_static.creation_timestamp.rfc3339
    ModifiedAt = time_static.modification_timestamp.rfc3339
  })
}
