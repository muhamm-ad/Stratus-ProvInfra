output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "subnet_ids" {
  description = "Subnet IDs by tier"
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

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = aws_nat_gateway.main.id
}

output "nat_gateway_public_ip" {
  description = "NAT Gateway public IP (Elastic IP)"
  value       = aws_eip.nat.public_ip
}

output "route_table_public_id" {
  description = "Public route table ID"
  value       = aws_route_table.public.id
}

output "route_table_private_id" {
  description = "Private route table ID"
  value       = aws_route_table.private.id
}
