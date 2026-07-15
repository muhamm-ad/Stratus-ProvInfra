output "network_name" {
  description = "GCP VPC Network name"
  value       = module.network.network_name
}

output "instances" {
  description = "GCP Compute instances details"
  value = {
    linux_instances = [
      for i, vm in module.compute.linux_instances : {
        id           = vm.id
        name         = vm.name
        internal_ip  = vm.internal_ip
        external_ip  = try(vm.external_ip, "Not assigned")
        machine_type = vm.machine_type
      }
    ]
    windows_instances = [
      for i, vm in module.compute.windows_instances : {
        id           = vm.id
        name         = vm.name
        internal_ip  = vm.internal_ip
        external_ip  = try(vm.external_ip, "Not assigned")
        machine_type = vm.machine_type
      }
    ]
  }
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
        provider = "gcp"
        os       = "linux"
        ip       = try(vm.external_ip, vm.internal_ip)
        region   = local.gcp_config.region
        state    = "running"
      }],
      [for vm in module.compute.windows_instances : {
        id       = vm.id
        name     = vm.name
        provider = "gcp"
        os       = "windows"
        ip       = vm.internal_ip
        region   = local.gcp_config.region
        state    = "running"
      }]
    )
  }
}
