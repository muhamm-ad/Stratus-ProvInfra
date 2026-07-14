locals {
  # Naming prefix (used across all providers)
  name_prefix = "${var.environment}_${var.project_name}"

  enable_aws   = contains(keys(var.providers), "aws")
  enable_azure = contains(keys(var.providers), "azure")
  enable_gcp   = contains(keys(var.providers), "gcp")

  # Common tags applied to all resources
  common_tags = merge(
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform"
      CreatedAt   = time_static.creation_timestamp.rfc3339
      ModifiedAt  = time_static.modification_timestamp.rfc3339
      Owner       = var.owner_email
    },
    var.additional_tags
  )
}

# ----------------------------------------------------------------------------------------------------------------------
# AWS Resources (conditional on var.enable_aws)
# ----------------------------------------------------------------------------------------------------------------------

module "aws_vpc" {
  count  = local.enable_aws ? 1 : 0
  source = "../modules/aws/vpc"

  name_prefix = local.name_prefix
  cidr_block  = var.providers.aws.vpc_cidr
  region      = var.providers.aws.region

  subnet_configs = {
    linux = {
      cidr = var.instances.linux.cidr.aws
      az   = data.aws_availability_zones.available[0].names[0]
    }
    windows = {
      cidr = var.instances.windows.cidr.aws
      az   = data.aws_availability_zones.available[0].names[1]
    }
  }

  tags = local.common_tags
}

module "aws_security" {
  count  = local.enable_aws ? 1 : 0
  source = "../modules/aws/security"

  name_prefix = local.name_prefix
  vpc_id      = module.aws_vpc[0].vpc_id

  ssh_public_key_path = var.security.ssh.public_key_path

  tags = local.common_tags
}

module "aws_compute" {
  count  = local.enable_aws ? 1 : 0
  source = "../modules/aws/compute"

  name_prefix = local.name_prefix

  linux_instances = {
    count             = var.instances.linux.count
    instance_type     = var.instances.linux.instance_type.aws
    subnet_id         = module.aws_vpc[0].subnet_ids.linux
    security_group_id = module.aws_security[0].security_group_id
    key_name          = module.aws_security[0].key_name
    user_data         = "#!/bin/bash\n\n# Install Nginx\napt-get update\napt-get install -y nginx"
  }

  windows_instances = {
    count             = var.instances.windows.count
    instance_type     = var.instances.windows.instance_type.aws
    subnet_id         = module.aws_vpc[0].subnet_ids.windows
    security_group_id = module.aws_security[0].security_group_id
    key_name          = module.aws_security[0].key_name
    user_data         = "#!/bin/powershell\n\n# Install IIS\nInstall-WindowsFeature -Name Web-Server -IncludeManagementTools"
  }

  tags = local.common_tags
}

# Data source for AWS availability zones
data "aws_availability_zones" "available" {
  count = local.enable_aws ? 1 : 0
  state = "available"
  filter {
    name   = "region-name"
    values = [var.providers.aws.region]
  }
}


# ----------------------------------------------------------------------------------------------------------------------
# Azure Resources (conditional on var.enable_azure)
# ----------------------------------------------------------------------------------------------------------------------

module "azure_network" {
  count  = local.enable_azure ? 1 : 0
  source = "../modules/azure/network"

  name_prefix         = local.name_prefix
  resource_group_name = coalesce(var.providers.azure.resource_group_name, "${local.name_prefix}_rg")
  location            = var.providers.azure.location
  vnet_cidr           = var.providers.azure.vnet_cidr
  linux_count         = var.instances.linux.count

  subnet_configs = {
    linux = {
      cidr = var.instances.linux.cidr.azure
    }
    windows = {
      cidr = var.instances.windows.cidr.azure
    }
  }

  tags = local.common_tags
}

module "azure_nsg" {
  count  = local.enable_azure ? 1 : 0
  source = "../modules/azure/nsg"

  name_prefix         = local.name_prefix
  resource_group_name = module.azure_network[0].resource_group_name
  location            = var.providers.azure.location

  tags = local.common_tags
}

module "azure_compute" {
  count  = local.enable_azure ? 1 : 0
  source = "../modules/azure/compute"

  name_prefix         = local.name_prefix
  resource_group_name = module.azure_network[0].resource_group_name
  location            = var.providers.azure.location
  ssh_public_key_path = var.security.ssh.public_key_path

  linux_instances = {
    count                     = var.instances.linux.count
    vm_size                   = var.instances.linux.instance_type.azure
    subnet_id                 = module.azure_network[0].subnet_ids.linux
    network_security_group_id = module.azure_nsg[0].nsg_id
    public_ip_ids             = module.azure_network[0].public_ip_ids
  }

  windows_instances = {
    count                     = var.instances.windows.count
    vm_size                   = var.instances.windows.instance_type.azure
    subnet_id                 = module.azure_network[0].subnet_ids.windows
    network_security_group_id = module.azure_nsg[0].nsg_id
    admin_username            = var.security.windows.username
    admin_password            = var.security.windows.password # TODO: Add password via env var
  }

  tags = local.common_tags
}

# ----------------------------------------------------------------------------------------------------------------------
# GCP Resources (conditional on var.enable_gcp)
# ----------------------------------------------------------------------------------------------------------------------

module "gcp_network" {
  count  = local.enable_gcp ? 1 : 0
  source = "../modules/gcp/network"

  name_prefix  = local.name_prefix
  project_id   = var.providers.gcp.project_id
  region       = var.providers.gcp.region
  network_cidr = var.providers.gcp.network_cidr

  subnet_configs = {
    linux = {
      cidr = var.instances.linux.cidr.gcp
    }
    windows = {
      cidr = var.instances.windows.cidr.gcp
    }
  }

  tags = local.common_tags
}

module "gcp_firewall" {
  count  = local.enable_gcp ? 1 : 0
  source = "../modules/gcp/firewall"

  name_prefix  = local.name_prefix
  project_id   = var.providers.gcp.project_id
  network_name = module.gcp_network[0].network_name

  tags = local.common_tags
}

module "gcp_compute" {
  count  = local.enable_gcp ? 1 : 0
  source = "../modules/gcp/compute"

  name_prefix = local.name_prefix
  project_id  = var.providers.gcp.project_id
  region      = var.providers.gcp.region

  linux_instances = {
    count        = var.instances.linux.count
    machine_type = var.instances.linux.instance_type.gcp
    subnet_name  = module.gcp_network[0].subnet_names.linux
  }

  windows_instances = {
    count          = var.instances.windows.count
    machine_type   = var.instances.windows.instance_type.gcp
    subnet_name    = module.gcp_network[0].subnet_names.windows
    admin_username = var.security.windows.username
    admin_password = var.security.windows.password # TODO: Add password via env var
  }

  tags = local.common_tags
}
