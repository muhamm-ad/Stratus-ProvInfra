output "resource_group" {
  description = "Azure Resource Group name"
  value       = module.network.resource_group_name
}

output "vnet_id" {
  description = "Azure VNet ID"
  value       = module.network.vnet_id
}

output "instances" {
  description = "Azure VM instances details"
  value = {
    linux_instances = [
      for i, vm in module.compute.linux_instances : {
        id         = vm.id
        private_ip = vm.private_ip
        public_ip  = try(vm.public_ip, "Not assigned")
        name       = vm.name
        vm_size    = vm.vm_size
      }
    ]
    windows_instances = [
      for i, vm in module.compute.windows_instances : {
        id         = vm.id
        private_ip = vm.private_ip
        public_ip  = try(vm.public_ip, "Not assigned")
        name       = vm.name
        vm_size    = vm.vm_size
      }
    ]
  }
}

output "nsg_id" {
  description = "Azure Network Security Group ID"
  value       = module.nsg.nsg_id
}

# Inventory (for Stratus Gateway integration)
output "inventory" {
  description = "VM inventory for this cloud (formatted for Stratus Gateway)"
  value = {
    total_vms = try(var.instances.linux.count, 0) + try(var.instances.windows.count, 0)
    vms = concat(
      [for vm in module.compute.linux_instances : {
        id       = vm.id
        name     = vm.name
        provider = "azure"
        os       = "linux"
        ip       = vm.private_ip
        region   = local.azure_config.location
        state    = "running"
      }],
      [for vm in module.compute.windows_instances : {
        id       = vm.id
        name     = vm.name
        provider = "azure"
        os       = "windows"
        ip       = vm.private_ip
        region   = local.azure_config.location
        state    = "running"
      }]
    )
  }
}
