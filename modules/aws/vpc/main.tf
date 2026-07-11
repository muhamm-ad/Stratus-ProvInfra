terraform {
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
      Name = var.name_prefix
    }
  )
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-igw"
    }
  )
}

resource "aws_subnet" "linux" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_configs.linux.cidr
  availability_zone       = var.subnet_configs.linux.az
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-subnet-linux"
      Tier = "public"
    }
  )
}

resource "aws_subnet" "windows" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_configs.windows.cidr
  availability_zone = var.subnet_configs.windows.az

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-subnet-windows"
      Tier = "private"
    }
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-rt-public"
    }
  )
}

resource "aws_route_table_association" "linux" {
  subnet_id      = aws_subnet.linux.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-eip-nat"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.linux.id

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-nat-gw"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-rt-private"
    }
  )
}

resource "aws_route_table_association" "windows" {
  subnet_id      = aws_subnet.windows.id
  route_table_id = aws_route_table.private.id
}

resource "aws_network_acl" "main" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [aws_subnet.linux.id, aws_subnet.windows.id]

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-nacl"
    }
  )
}
