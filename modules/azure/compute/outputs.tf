output "linux_instances" {
  value = [
    for i, vm in azurerm_linux_virtual_machine.main : {
      id         = vm.id
      name       = vm.name
      private_ip = vm.private_ip_address
      public_ip  = try(azurerm_network_interface.linux[i].ip_configuration[0].public_ip_address, null)
      vm_size    = vm.size
    }
  ]
}

output "windows_instances" {
  value = [
    for i, vm in azurerm_windows_virtual_machine.main : {
      id         = vm.id
      name       = vm.name
      private_ip = vm.private_ip_address
      public_ip  = null
      vm_size    = vm.size
    }
  ]
}
