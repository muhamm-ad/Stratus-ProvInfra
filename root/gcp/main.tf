locals {
  name_prefix = "${var.environment}_${var.project_name}"

  gcp_config = var.cloud_providers.gcp

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

module "network" {
  source = "../../modules/gcp/network"

  name_prefix  = local.name_prefix
  project_id   = local.gcp_config.project_id
  region       = local.gcp_config.region
  network_cidr = local.gcp_config.network_cidr

  subnet_configs = merge(
    local.enable_linux ? {
      linux = {
        cidr = local.linux_config.cidr.gcp
      }
    } : {},
    local.enable_windows ? {
      windows = {
        cidr = local.windows_config.cidr.gcp
      }
    } : {}
  )

  tags = merge(local.common_tags, {
    CreatedAt  = time_static.creation_timestamp.rfc3339
    ModifiedAt = time_static.modification_timestamp.rfc3339
  })
}

module "firewall" {
  source = "../../modules/gcp/firewall"

  name_prefix  = local.name_prefix
  project_id   = local.gcp_config.project_id
  network_name = module.network.network_name

  tags = merge(local.common_tags, {
    CreatedAt  = time_static.creation_timestamp.rfc3339
    ModifiedAt = time_static.modification_timestamp.rfc3339
  })
}

module "compute" {
  source = "../../modules/gcp/compute"

  name_prefix = local.name_prefix
  project_id  = local.gcp_config.project_id
  region      = local.gcp_config.region

  linux_instances = local.enable_linux ? {
    count        = local.linux_config.count
    machine_type = local.linux_config.instance_type.gcp
    subnet_name  = module.network.subnet_names.linux
    user_data    = local.linux_config.script
    username     = local.linux_config.username != "" ? local.linux_config.username : local.username
    disk         = local.linux_config.disk.gcp
  } : null

  windows_instances = local.enable_windows ? {
    count              = local.windows_config.count
    machine_type       = local.windows_config.instance_type.gcp
    subnet_name        = module.network.subnet_names.windows
    user_data          = local.windows_config.script
    username           = local.windows_config.username != "" ? local.windows_config.username : local.username
    password_to_change = local.windows_config.password_to_change != "" ? local.windows_config.password_to_change : "Stratus@123"
    disk               = local.windows_config.disk.gcp
  } : null

  tags = merge(local.common_tags, {
    CreatedAt  = time_static.creation_timestamp.rfc3339
    ModifiedAt = time_static.modification_timestamp.rfc3339
  })
}
