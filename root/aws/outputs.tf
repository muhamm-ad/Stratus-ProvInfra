output "vpc_id" {
  description = "AWS VPC ID"
  value       = module.vpc.vpc_id
}

output "security_group_id" {
  description = "AWS Security Group ID"
  value       = module.security.security_group_id
}

# output "instances" {
#   description = "AWS EC2 instances details"
#   value = {
#     linux_instances = [
#       for i, vm in module.compute.linux_instances : {
#         id            = vm.id
#         private_ip    = vm.private_ip
#         public_ip     = vm.public_ip
#         public_dns    = vm.public_dns
#         instance_type = vm.instance_type
#       }
#     ]
#     windows_instances = [
#       for i, vm in module.compute.windows_instances : {
#         id            = vm.id
#         private_ip    = vm.private_ip
#         public_ip     = vm.public_ip
#         public_dns    = vm.public_dns
#         instance_type = vm.instance_type
#       }
#     ]
#   }
# }

# Inventory (for Stratus Gateway integration)
output "inventory" {
  description = "VM inventory for this cloud (formatted for Stratus Gateway)"
  value = {
    total_vms = try(var.instances.linux.count, 0) + try(var.instances.windows.count, 0)
    vms = concat(
      [for vm in module.compute.linux_instances : {
        id         = vm.id
        name       = vm.tags.Name
        provider   = "aws"
        os         = "linux"
        type       = vm.instance_type
        private_ip = vm.private_ip
        public_ip  = vm.public_ip
        public_dns = vm.public_dns
        region     = local.aws_config.region
        state      = "running"
      }],
      [for vm in module.compute.windows_instances : {
        id         = vm.id
        name       = vm.tags.Name
        provider   = "aws"
        os         = "windows"
        type       = vm.instance_type
        private_ip = vm.private_ip
        public_ip  = vm.public_ip
        public_dns = vm.public_dns
        region     = local.aws_config.region
        state      = "running"
      }]
    )
  }
}
