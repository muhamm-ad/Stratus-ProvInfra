output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "subnet_ids" {
  description = "Subnet IDs by workload"
  value       = { for workload, subnet in aws_subnet.workload : workload => subnet.id }
}

output "subnet_cidrs" {
  description = "Subnet CIDR blocks"
  value       = { for workload, subnet in aws_subnet.workload : workload => subnet.cidr_block }
}

output "igw_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.main.id
}

output "route_table_public_id" {
  description = "Public route table ID"
  value       = aws_route_table.public.id
}
