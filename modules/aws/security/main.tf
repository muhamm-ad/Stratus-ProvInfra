terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_security_group" "main" {
  vpc_id      = var.vpc_id
  name        = "${var.name_prefix}_sg"
  description = "Security group for ${var.name_prefix}"

  tags = merge(
    var.tags,
    { Name = "${var.name_prefix}_sg" }
  )
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.main.id
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"

  tags = { Name = "${var.name_prefix}_ssh" }
}

resource "aws_vpc_security_group_ingress_rule" "rdp" {
  security_group_id = aws_security_group.main.id
  from_port         = 3389
  to_port           = 3389
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"

  tags = { Name = "${var.name_prefix}_rdp" }
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.main.id
  from_port         = 0
  to_port           = 0
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = { Name = "${var.name_prefix}_egress" }
}

resource "aws_key_pair" "main" {
  key_name   = "${var.name_prefix}_key"
  public_key = file(pathexpand(var.ssh_public_key_path))

  tags = merge(
    var.tags,
    { Name = "${var.name_prefix}_key" }
  )
}
