terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}_vpc"
    }
  )
}

resource "aws_subnet" "workload" {
  for_each = var.subnet_configs

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}_subnet_${each.key}"
      Tier = "public"
    }
  )
}

moved {
  from = aws_subnet.linux
  to   = aws_subnet.workload["linux"]
}

moved {
  from = aws_subnet.windows
  to   = aws_subnet.workload["windows"]
}
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}_igw"
    }
  )
}


# Adopt the VPC's auto-created main route table instead of creating a second one.
# Every VPC gets a default RT; managing it here avoids an orphaned unused table.
resource "aws_default_route_table" "public" {
  default_route_table_id = aws_vpc.main.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}_rt_public"
    }
  )
}