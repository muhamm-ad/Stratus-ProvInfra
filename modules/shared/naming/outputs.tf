output "name_prefix" {
  value = local.name_prefix
}

output "aws_prefix" {
  value = local.aws_prefix
}

output "azure_prefix" {
  value = local.azure_prefix
}

output "gcp_prefix" {
  value = local.gcp_prefix
}

output "linux_names" {
  value = local.linux_names
}

output "windows_names" {
  value = local.windows_names
}

output "resource_names" {
  value = {
    vpc              = local.vpc_name
    subnet_linux     = local.subnet_linux_name
    subnet_windows   = local.subnet_windows_name
    nat_gateway      = local.nat_gateway_name
    internet_gateway = local.internet_gateway_name
    security_group   = local.security_group_name
    network_sg       = local.network_sg_name
    ssh_key          = local.ssh_key_name
    cert             = local.cert_name
  }
}
