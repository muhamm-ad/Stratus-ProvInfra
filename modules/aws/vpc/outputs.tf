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
  value = {
    linux   = aws_subnet.linux.id
    windows = aws_subnet.windows.id
  }
}

output "subnet_cidrs" {
  description = "Subnet CIDR blocks"
  value = {
    linux   = aws_subnet.linux.cidr_block
    windows = aws_subnet.windows.cidr_block
  }
}

output "igw_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.main.id
}

output "route_table_public_id" {
  description = "Public route table ID"
  value       = aws_route_table.public.id
}
