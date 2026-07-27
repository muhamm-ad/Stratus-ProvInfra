output "linux_instances" {
  value = [
    for linux in azurerm_linux_virtual_machine.main : {
      id                 = nonsensitive(linux.id)
      name               = nonsensitive(linux.name)
      private_ip_address = nonsensitive(linux.private_ip_address)
      public_ip_address  = nonsensitive(linux.public_ip_address)
      # public_dns         = nonsensitive(linux.public_dns)
      size = nonsensitive(linux.size)
    }
  ]
}

output "windows_instances" {
  value = [
    for win in azurerm_windows_virtual_machine.main : {
      id                 = nonsensitive(win.id)
      name               = nonsensitive(win.name)
      private_ip_address = nonsensitive(win.private_ip_address)
      public_ip_address  = nonsensitive(win.public_ip_address)
      # public_dns         = nonsensitive(win.public_dns)
      size = nonsensitive(win.size)
    }
  ]
}
