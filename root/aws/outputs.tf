output "vpc_id" {
  description = "AWS VPC ID"
  value       = module.vpc.vpc_id
}

output "security_group_id" {
  description = "AWS Security Group ID"
  value       = module.security.security_group_id
}

output "instances" {
  description = "AWS EC2 instances details"
  value = {
    linux_instances   = module.compute.linux_instances
    windows_instances = module.compute.windows_instances
  }
}

# Inventory (for Stratus Gateway integration)
output "inventory" {
  description = "VM inventory for this cloud (formatted for Stratus Gateway)"
  value = {
    total_vms = try(var.instances.linux.count, 0) + try(var.instances.windows.count, 0)
    vms = concat(
      [for vm in module.compute.linux_instances : {
        id         = vm.id
        name       = vm.name
        provider   = "aws"
        os         = "linux"
        type       = vm.type
        private_ip = vm.private_ip
        public_ip  = vm.public_ip
        public_dns = vm.public_dns
        region     = local.aws_config.region
        # state      = "running"
      }],
      [for vm in module.compute.windows_instances : {
        id         = vm.id
        name       = vm.name
        provider   = "aws"
        os         = "windows"
        type       = vm.type
        private_ip = vm.private_ip
        public_ip  = vm.public_ip
        public_dns = vm.public_dns
        region     = local.aws_config.region
        # state      = "running"
      }]
    )
  }
}
