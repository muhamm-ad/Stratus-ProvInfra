output "linux_instances" {
  value = [
    for i, vm in google_compute_instance.linux : {
      id           = vm.id
      name         = vm.name
      internal_ip  = vm.network_interface[0].network_ip
      external_ip  = try(vm.network_interface[0].access_config[0].nat_ip, null)
      machine_type = vm.machine_type
    }
  ]
}

output "windows_instances" {
  value = [
    for vm in google_compute_instance.windows : {
      id           = vm.id
      name         = vm.name
      internal_ip  = vm.network_interface[0].network_ip
      external_ip  = null
      machine_type = vm.machine_type
    }
  ]
}
