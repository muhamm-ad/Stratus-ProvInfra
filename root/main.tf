# ----------------------------------------------------------------------------------------------------------------------
# AWS Resources (conditional on var.enable_aws)
# ----------------------------------------------------------------------------------------------------------------------

module "aws_vpc" {
  count  = var.enable_aws ? 1 : 0
  source = "../modules/aws/vpc"

  name_prefix = local.name_prefix
  cidr_block  = var.aws_vpc_cidr
  region      = var.aws_region

  subnet_configs = {
    linux = {
      cidr = local.aws_subnet_cidr_linux
      az   = data.aws_availability_zones.available[0].names[0]
    }
    windows = {
      cidr = local.aws_subnet_cidr_windows
      az   = data.aws_availability_zones.available[0].names[1]
    }
  }

  tags = local.common_tags
}

module "aws_security" {
  count  = var.enable_aws ? 1 : 0
  source = "../modules/aws/security"

  name_prefix = local.name_prefix
  vpc_id      = module.aws_vpc[0].vpc_id

  ssh_key_name        = "${local.name_prefix}_key"
  ssh_public_key_path = var.ssh_public_key_path

  tags = local.common_tags
}

module "aws_compute" {
  count  = var.enable_aws ? 1 : 0
  source = "../modules/aws/compute"

  name_prefix = local.name_prefix

  linux_instances = {
    count             = var.linux_vm_count
    instance_type     = var.linux_instance_type.aws
    subnet_id         = module.aws_vpc[0].subnet_ids.linux
    security_group_id = module.aws_security[0].security_group_id
    key_name          = module.aws_security[0].key_name
  }

  windows_instances = {
    count             = var.windows_vm_count
    instance_type     = var.windows_instance_type.aws
    subnet_id         = module.aws_vpc[0].subnet_ids.windows
    security_group_id = module.aws_security[0].security_group_id
  }

  tags = local.common_tags
}

# Data source for AWS availability zones
data "aws_availability_zones" "available" {
  count = var.enable_aws ? 1 : 0
  state = "available"
  filter {
    name   = "region-name"
    values = [var.aws_region]
  }
}


# ----------------------------------------------------------------------------------------------------------------------
# Azure Resources (conditional on var.enable_azure)
# ----------------------------------------------------------------------------------------------------------------------

module "azure_network" {
  count  = var.enable_azure ? 1 : 0
  source = "../modules/azure/network"

  name_prefix         = local.name_prefix
  resource_group_name = coalesce(var.azure_resource_group_name, "${local.name_prefix}_rg")
  location            = var.azure_location
  vnet_cidr           = var.azure_vnet_cidr
  linux_count         = var.linux_vm_count

  subnet_configs = {
    linux = {
      cidr = local.azure_subnet_cidr_linux
    }
    windows = {
      cidr = local.azure_subnet_cidr_windows
    }
  }

  tags = local.common_tags
}

module "azure_nsg" {
  count  = var.enable_azure ? 1 : 0
  source = "../modules/azure/nsg"

  name_prefix         = local.name_prefix
  resource_group_name = module.azure_network[0].resource_group_name
  location            = var.azure_location

  tags = local.common_tags
}

module "azure_compute" {
  count  = var.enable_azure ? 1 : 0
  source = "../modules/azure/compute"

  name_prefix         = local.name_prefix
  resource_group_name = module.azure_network[0].resource_group_name
  location            = var.azure_location
  ssh_public_key_path = var.ssh_public_key_path

  linux_instances = {
    count                     = var.linux_vm_count
    vm_size                   = var.linux_instance_type.azure
    subnet_id                 = module.azure_network[0].subnet_ids.linux
    network_security_group_id = module.azure_nsg[0].nsg_id
    public_ip_ids             = module.azure_network[0].public_ip_ids
  }

  windows_instances = {
    count                     = var.windows_vm_count
    vm_size                   = var.windows_instance_type.azure
    subnet_id                 = module.azure_network[0].subnet_ids.windows
    network_security_group_id = module.azure_nsg[0].nsg_id
    admin_username            = var.windows_admin_username
    admin_password            = var.windows_admin_password
  }

  tags = local.common_tags
}

# ----------------------------------------------------------------------------------------------------------------------
# GCP Resources (conditional on var.enable_gcp)
# ----------------------------------------------------------------------------------------------------------------------

module "gcp_network" {
  count  = var.enable_gcp ? 1 : 0
  source = "../modules/gcp/network"

  name_prefix  = local.name_prefix
  project_id   = var.gcp_project_id
  region       = var.gcp_region
  network_cidr = var.gcp_network_cidr

  subnet_configs = {
    linux = {
      cidr = local.gcp_subnet_cidr_linux
    }
    windows = {
      cidr = local.gcp_subnet_cidr_windows
    }
  }

  tags = local.common_tags
}

module "gcp_firewall" {
  count  = var.enable_gcp ? 1 : 0
  source = "../modules/gcp/firewall"

  name_prefix  = local.name_prefix
  project_id   = var.gcp_project_id
  network_name = module.gcp_network[0].network_name

  tags = local.common_tags
}

module "gcp_compute" {
  count  = var.enable_gcp ? 1 : 0
  source = "../modules/gcp/compute"

  name_prefix = local.name_prefix
  project_id  = var.gcp_project_id
  region      = var.gcp_region

  linux_instances = {
    count        = var.linux_vm_count
    machine_type = var.linux_instance_type.gcp
    subnet_name  = module.gcp_network[0].subnet_names.linux
  }

  windows_instances = {
    count          = var.windows_vm_count
    machine_type   = var.windows_instance_type.gcp
    subnet_name    = module.gcp_network[0].subnet_names.windows
    admin_username = var.windows_admin_username
    admin_password = var.windows_admin_password
  }

  tags = local.common_tags
}
