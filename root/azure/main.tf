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
}

resource "time_static" "creation_timestamp" {}

resource "time_static" "modification_timestamp" {
  triggers = {
    always_recreate = timestamp()
  }
}

module "network" {
  source = "../../modules/azure/network"

  name_prefix         = local.name_prefix
  resource_group_name = coalesce(local.azure_config.resource_group_name, "${local.name_prefix}_rg")
  location            = local.azure_config.location
  vnet_cidr           = local.azure_config.vnet_cidr
  linux_count         = try(local.linux_config.count, 0)

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

module "nsg" {
  source = "../../modules/azure/nsg"

  name_prefix         = local.name_prefix
  resource_group_name = module.network.resource_group_name
  location            = local.azure_config.location

  tags = merge(local.common_tags, {
    CreatedAt  = time_static.creation_timestamp.rfc3339
    ModifiedAt = time_static.modification_timestamp.rfc3339
  })
}

module "compute" {
  source = "../../modules/azure/compute"

  name_prefix         = local.name_prefix
  resource_group_name = module.network.resource_group_name
  location            = local.azure_config.location
  ssh_public_key_path = var.security.ssh.public_key_path

  linux_instances = local.enable_linux ? {
    count                     = local.linux_config.count
    vm_size                   = local.linux_config.instance_type.azure
    subnet_id                 = module.network.subnet_ids.linux
    network_security_group_id = module.nsg.nsg_id
    public_ip_ids             = module.network.public_ip_ids
  } : null

  windows_instances = local.enable_windows ? {
    count                     = local.windows_config.count
    vm_size                   = local.windows_config.instance_type.azure
    subnet_id                 = module.network.subnet_ids.windows
    network_security_group_id = module.nsg.nsg_id
    admin_username            = var.security.windows.username
    admin_password            = var.security.windows.password # TODO: Add password via env var
  } : null

  tags = merge(local.common_tags, {
    CreatedAt  = time_static.creation_timestamp.rfc3339
    ModifiedAt = time_static.modification_timestamp.rfc3339
  })
}
