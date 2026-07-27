output "vnet_id" {
  value = azurerm_virtual_network.main.id
}

output "subnet_ids" {
  value = { for workload, subnet in azurerm_subnet.workload : workload => subnet.id }
}

output "public_ips" {
  value = {
    linux = {
      ids       = [for ip in azurerm_public_ip.linux[*] : ip.id]
      addresses = [for ip in azurerm_public_ip.linux[*] : ip.ip_address]
    }
    windows = {
      ids       = [for ip in azurerm_public_ip.windows[*] : ip.id]
      addresses = [for ip in azurerm_public_ip.windows[*] : ip.ip_address]
    }
  }
}


output "network_interface_ids" {
  value = {
    linux   = [for nic in azurerm_network_interface.linux[*] : nic.id]
    windows = [for nic in azurerm_network_interface.windows[*] : nic.id]
  }
}