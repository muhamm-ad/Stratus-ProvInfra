locals {
  name_prefix = "${var.environment}_${var.project_name}"

  aws_config = var.cloud_providers.aws

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

data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name   = "region-name"
    values = [local.aws_config.region]
  }
}

module "vpc" {
  source = "../../modules/aws/vpc"

  name_prefix = local.name_prefix
  cidr_block  = local.aws_config.vpc_cidr
  region      = local.aws_config.region

  subnet_configs = merge(
    local.enable_linux ? {
      linux = {
        cidr = local.linux_config.cidr.aws
        az   = data.aws_availability_zones.available.names[0]
      }
    } : {},
    local.enable_windows ? {
      windows = {
        cidr = local.windows_config.cidr.aws
        az   = data.aws_availability_zones.available.names[1]
      }
    } : {}
  )

  tags = merge(local.common_tags, {
    CreatedAt  = time_static.creation_timestamp.rfc3339
    ModifiedAt = time_static.modification_timestamp.rfc3339
  })
}

module "security" {
  source = "../../modules/aws/security"

  name_prefix = local.name_prefix
  vpc_id      = module.vpc.vpc_id

  ssh_public_key_path = var.security.ssh.public_key_path

  tags = merge(local.common_tags, {
    CreatedAt  = time_static.creation_timestamp.rfc3339
    ModifiedAt = time_static.modification_timestamp.rfc3339
  })
}

module "compute" {
  source = "../../modules/aws/compute"

  name_prefix = local.name_prefix

  linux_instances = local.enable_linux ? {
    count             = local.linux_config.count
    instance_type     = local.linux_config.instance_type.aws
    subnet_id         = module.vpc.subnet_ids.linux
    security_group_id = module.security.security_group_id
    key_name          = module.security.key_name
    user_data         = "#!/bin/bash\n\n# Install Nginx\napt-get update\napt-get install -y nginx"
  } : null

  windows_instances = local.enable_windows ? {
    count             = local.windows_config.count
    instance_type     = local.windows_config.instance_type.aws
    subnet_id         = module.vpc.subnet_ids.windows
    security_group_id = module.security.security_group_id
    key_name          = module.security.key_name
    user_data         = "#!/bin/powershell\n\n# Install IIS\nInstall-WindowsFeature -Name Web-Server -IncludeManagementTools"
  } : null

  tags = merge(local.common_tags, {
    CreatedAt  = time_static.creation_timestamp.rfc3339
    ModifiedAt = time_static.modification_timestamp.rfc3339
  })
}
