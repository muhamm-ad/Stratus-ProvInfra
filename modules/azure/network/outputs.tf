output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "vnet_id" {
  value = azurerm_virtual_network.main.id
}

output "subnet_ids" {
  value = { for workload, subnet in azurerm_subnet.workload : workload => subnet.id }
}

output "public_ip_ids" {
  value = azurerm_public_ip.linux[*].id
}

output "public_ip_addresses" {
  value = azurerm_public_ip.linux[*].ip_address
}
