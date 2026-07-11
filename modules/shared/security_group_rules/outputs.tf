output "ssh_ingress_rule" {
  value = local.ssh_rules
}

output "rdp_ingress_rule" {
  value = local.rdp_rules
}

output "egress_rule" {
  value = local.egress_all
}
