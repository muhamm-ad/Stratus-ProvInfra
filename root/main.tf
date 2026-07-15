locals {
  # Naming prefix (used across all providers)
  name_prefix = "${var.environment}_${var.project_name}"

  enable_aws   = var.cloud_providers.aws != null
  enable_azure = var.cloud_providers.azure != null
  enable_gcp   = var.cloud_providers.gcp != null

  aws_config   = var.cloud_providers.aws
  azure_config = var.cloud_providers.azure
  gcp_config   = var.cloud_providers.gcp

  enable_linux   = var.instances.linux != null
  enable_windows = var.instances.windows != null

  linux_config   = var.instances.linux
  windows_config = var.instances.windows

  # Common tags applied to all resources
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

# Timestamp for modification time - this will update on each apply
resource "time_static" "modification_timestamp" {
  triggers = {
    # This forces the resource to be recreated on each apply
    always_recreate = timestamp()
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# AWS Resources (conditional on var.enable_aws)
# ----------------------------------------------------------------------------------------------------------------------

module "aws_vpc" {
  count  = local.enable_aws ? 1 : 0
  source = "../modules/aws/vpc"

  name_prefix = local.name_prefix
  cidr_block  = local.aws_config.vpc_cidr
  region      = local.aws_config.region

  subnet_configs = merge(
    local.enable_linux ? {
      linux = {
        cidr = local.linux_config.cidr.aws
        az   = data.aws_availability_zones.available[0].names[0]
      }
    } : {},
    local.enable_windows ? {
      windows = {
        cidr = local.windows_config.cidr.aws
        az   = data.aws_availability_zones.available[0].names[1]
      }
    } : {}
  )

  tags = merge(local.common_tags, {
    CreatedAt  = time_static.creation_timestamp.rfc3339
    ModifiedAt = time_static.modification_timestamp.rfc3339
  })
}

module "aws_security" {
  count  = local.enable_aws ? 1 : 0
  source = "../modules/aws/security"

  name_prefix = local.name_prefix
  vpc_id      = module.aws_vpc[0].vpc_id

  ssh_public_key_path = var.security.ssh.public_key_path

  tags = merge(local.common_tags, {
    CreatedAt  = time_static.creation_timestamp.rfc3339
    ModifiedAt = time_static.modification_timestamp.rfc3339
  })
}

module "aws_compute" {
  count  = local.enable_aws ? 1 : 0
  source = "../modules/aws/compute"

  name_prefix = local.name_prefix

  linux_instances = local.enable_linux ? {
    count             = local.linux_config.count
    instance_type     = local.linux_config.instance_type.aws
    subnet_id         = module.aws_vpc[0].subnet_ids.linux
    security_group_id = module.aws_security[0].security_group_id
    key_name          = module.aws_security[0].key_name
    user_data         = "#!/bin/bash\n\n# Install Nginx\napt-get update\napt-get install -y nginx"
  } : null

  windows_instances = local.enable_windows ? {
    count             = local.windows_config.count
    instance_type     = local.windows_config.instance_type.aws
    subnet_id         = module.aws_vpc[0].subnet_ids.windows
    security_group_id = module.aws_security[0].security_group_id
    key_name          = module.aws_security[0].key_name
    user_data         = "#!/bin/powershell\n\n# Install IIS\nInstall-WindowsFeature -Name Web-Server -IncludeManagementTools"
  } : null

  tags = merge(local.common_tags, {
    CreatedAt  = time_static.creation_timestamp.rfc3339
    ModifiedAt = time_static.modification_timestamp.rfc3339
  })
}

# Data source for AWS availability zones
data "aws_availability_zones" "available" {
  count = local.enable_aws ? 1 : 0
  state = "available"
  filter {
    name   = "region-name"
    values = [local.aws_config.region]
  }
}


# ----------------------------------------------------------------------------------------------------------------------
# Azure Resources (conditional on var.enable_azure)
# ----------------------------------------------------------------------------------------------------------------------

module "azure_network" {
  count  = local.enable_azure ? 1 : 0
  source = "../modules/azure/network"

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

module "azure_nsg" {
  count  = local.enable_azure ? 1 : 0
  source = "../modules/azure/nsg"

  name_prefix         = local.name_prefix
  resource_group_name = module.azure_network[0].resource_group_name
  location            = local.azure_config.location

  tags = merge(local.common_tags, {
    CreatedAt  = time_static.creation_timestamp.rfc3339
    ModifiedAt = time_static.modification_timestamp.rfc3339
  })
}

module "azure_compute" {
  count  = local.enable_azure ? 1 : 0
  source = "../modules/azure/compute"

  name_prefix         = local.name_prefix
  resource_group_name = module.azure_network[0].resource_group_name
  location            = local.azure_config.location
  ssh_public_key_path = var.security.ssh.public_key_path

  linux_instances = local.enable_linux ? {
    count                     = local.linux_config.count
    vm_size                   = local.linux_config.instance_type.azure
    subnet_id                 = module.azure_network[0].subnet_ids.linux
    network_security_group_id = module.azure_nsg[0].nsg_id
    public_ip_ids             = module.azure_network[0].public_ip_ids
  } : null

  windows_instances = local.enable_windows ? {
    count                     = local.windows_config.count
    vm_size                   = local.windows_config.instance_type.azure
    subnet_id                 = module.azure_network[0].subnet_ids.windows
    network_security_group_id = module.azure_nsg[0].nsg_id
    admin_username            = var.security.windows.username
    admin_password            = var.security.windows.password # TODO: Add password via env var
  } : null

  tags = merge(local.common_tags, {
    CreatedAt  = time_static.creation_timestamp.rfc3339
    ModifiedAt = time_static.modification_timestamp.rfc3339
  })
}

# ----------------------------------------------------------------------------------------------------------------------
# GCP Resources (conditional on var.enable_gcp)
# ----------------------------------------------------------------------------------------------------------------------

module "gcp_network" {
  count  = local.enable_gcp ? 1 : 0
  source = "../modules/gcp/network"

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

module "gcp_firewall" {
  count  = local.enable_gcp ? 1 : 0
  source = "../modules/gcp/firewall"

  name_prefix  = local.name_prefix
  project_id   = local.gcp_config.project_id
  network_name = module.gcp_network[0].network_name

  tags = merge(local.common_tags, {
    CreatedAt  = time_static.creation_timestamp.rfc3339
    ModifiedAt = time_static.modification_timestamp.rfc3339
  })
}

module "gcp_compute" {
  count  = local.enable_gcp ? 1 : 0
  source = "../modules/gcp/compute"

  name_prefix = local.name_prefix
  project_id  = local.gcp_config.project_id
  region      = local.gcp_config.region

  linux_instances = local.enable_linux ? {
    count        = local.linux_config.count
    machine_type = local.linux_config.instance_type.gcp
    subnet_name  = module.gcp_network[0].subnet_names.linux
  } : null

  windows_instances = local.enable_windows ? {
    count          = local.windows_config.count
    machine_type   = local.windows_config.instance_type.gcp
    subnet_name    = module.gcp_network[0].subnet_names.windows
    admin_username = var.security.windows.username
    admin_password = var.security.windows.password # TODO: Add password via env var
  } : null

  tags = merge(local.common_tags, {
    CreatedAt  = time_static.creation_timestamp.rfc3339
    ModifiedAt = time_static.modification_timestamp.rfc3339
  })
}
