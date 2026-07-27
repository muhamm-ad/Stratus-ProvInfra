output "linux_instances" {
  value = [
    for vm in azurerm_linux_virtual_machine.main : {
      id                 = vm.id
      name               = vm.name
      private_ip_address = vm.private_ip_address
      public_ip_address  = vm.public_ip_address
      size               = vm.size
    }
  ]
}

output "windows_instances" {
  value = [
    for vm in azurerm_windows_virtual_machine.main : {
      id                 = vm.id
      name               = vm.name
      private_ip_address = vm.private_ip_address
      public_ip_address  = vm.public_ip_address
      size               = vm.size
    }
  ]
}
