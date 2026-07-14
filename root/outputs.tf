output "deployment_summary" {
  description = "High-level summary of deployed resources"
  value = {
    environment  = var.environment
    project_name = var.project_name
    deployed_providers = {
      aws   = local.enable_aws
      azure = local.enable_azure
      gcp   = local.enable_gcp
    }
    vm_counts = {
      linux   = var.instances.linux.count
      windows = var.instances.windows.count
    }
  }
}

# AWS Outputs
output "aws_vpc_id" {
  description = "AWS VPC ID"
  value       = try(module.aws_vpc[0].vpc_id, null)
}

output "aws_instances" {
  description = "AWS EC2 instances details"
  value = try({
    linux_instances = [
      for i, vm in module.aws_compute[0].linux_instances : {
        id            = vm.id
        private_ip    = vm.private_ip
        public_ip     = vm.public_ip
        instance_type = vm.instance_type
      }
    ]
    windows_instances = [
      for i, vm in module.aws_compute[0].windows_instances : {
        id            = vm.id
        private_ip    = vm.private_ip
        instance_type = vm.instance_type
      }
    ]
  }, null)
}

output "aws_security_group_id" {
  description = "AWS Security Group ID"
  value       = try(module.aws_security[0].security_group_id, null)
}

output "aws_key_pair_name" {
  description = "AWS SSH Key Pair Name"
  value       = try(module.aws_security[0].key_name, null)
}

# Azure Outputs
output "azure_resource_group" {
  description = "Azure Resource Group name"
  value       = try(module.azure_network[0].resource_group_name, null)
}

output "azure_vnet_id" {
  description = "Azure VNet ID"
  value       = try(module.azure_network[0].vnet_id, null)
}

output "azure_instances" {
  description = "Azure VM instances details"
  value = try({
    linux_instances = [
      for i, vm in module.azure_compute[0].linux_instances : {
        id         = vm.id
        private_ip = vm.private_ip
        public_ip  = try(vm.public_ip, "Not assigned")
        name       = vm.name
        vm_size    = vm.vm_size
      }
    ]
    windows_instances = [
      for i, vm in module.azure_compute[0].windows_instances : {
        id         = vm.id
        private_ip = vm.private_ip
        public_ip  = try(vm.public_ip, "Not assigned")
        name       = vm.name
        vm_size    = vm.vm_size
      }
    ]
  }, null)
}

output "azure_nsg_id" {
  description = "Azure Network Security Group ID"
  value       = try(module.azure_nsg[0].nsg_id, null)
}

# GCP Outputs
output "gcp_network_name" {
  description = "GCP VPC Network name"
  value       = try(module.gcp_network[0].network_name, null)
}

output "gcp_instances" {
  description = "GCP Compute instances details"
  value = try({
    linux_instances = [
      for i, vm in module.gcp_compute[0].linux_instances : {
        id           = vm.id
        name         = vm.name
        internal_ip  = vm.internal_ip
        external_ip  = try(vm.external_ip, "Not assigned")
        machine_type = vm.machine_type
      }
    ]
    windows_instances = [
      for i, vm in module.gcp_compute[0].windows_instances : {
        id           = vm.id
        name         = vm.name
        internal_ip  = vm.internal_ip
        external_ip  = try(vm.external_ip, "Not assigned")
        machine_type = vm.machine_type
      }
    ]
  }, null)
}

# Aggregated Inventory (for Stratus Gateway integration)
output "inventory" {
  description = "Complete VM inventory across all providers (formatted for Stratus Gateway)"
  value = {
    aws = local.enable_aws ? {
      total_vms = var.instances.linux.count + var.instances.windows.count
      vms = concat(
        [for vm in try(module.aws_compute[0].linux_instances, []) : {
          id       = vm.id
          name     = vm.tags.Name
          provider = "aws"
          os       = "linux"
          ip       = vm.public_ip != "" ? vm.public_ip : vm.private_ip
          region   = var.providers.aws.region
          state    = "running"
        }],
        [for vm in try(module.aws_compute[0].windows_instances, []) : {
          id       = vm.id
          name     = vm.tags.Name
          provider = "aws"
          os       = "windows"
          ip       = vm.private_ip
          region   = var.providers.aws.region
          state    = "running"
        }]
      )
    } : null

    azure = local.enable_azure ? {
      total_vms = var.instances.linux.count + var.instances.windows.count
      vms = concat(
        [for vm in try(module.azure_compute[0].linux_instances, []) : {
          id       = vm.id
          name     = vm.name
          provider = "azure"
          os       = "linux"
          ip       = vm.private_ip
          region   = var.providers.azure.location
          state    = "running"
        }],
        [for vm in try(module.azure_compute[0].windows_instances, []) : {
          id       = vm.id
          name     = vm.name
          provider = "azure"
          os       = "windows"
          ip       = vm.private_ip
          region   = var.providers.azure.location
          state    = "running"
        }]
      )
    } : null

    gcp = local.enable_gcp ? {
      total_vms = var.instances.linux.count + var.instances.windows.count
      vms = concat(
        [for vm in try(module.gcp_compute[0].linux_instances, []) : {
          id       = vm.id
          name     = vm.name
          provider = "gcp"
          os       = "linux"
          ip       = try(vm.external_ip, vm.internal_ip)
          region   = var.providers.gcp.region
          state    = "running"
        }],
        [for vm in try(module.gcp_compute[0].windows_instances, []) : {
          id       = vm.id
          name     = vm.name
          provider = "gcp"
          os       = "windows"
          ip       = vm.internal_ip
          region   = var.providers.gcp.region
          state    = "running"
        }]
      )
    } : null
  }
  sensitive = false
}
