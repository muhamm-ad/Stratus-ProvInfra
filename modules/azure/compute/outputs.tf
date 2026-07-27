output "linux_instances" {
  value = [for linux in azurerm_linux_virtual_machine.main : linux]
}

output "windows_instances" {
  value = [for win in azurerm_windows_virtual_machine.main : win]
}
