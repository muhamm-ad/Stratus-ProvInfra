terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "windows" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Core-*"]
  }
}

resource "aws_instance" "linux" {
  count = var.linux_instances.count

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.linux_instances.instance_type
  subnet_id              = var.linux_instances.subnet_id
  vpc_security_group_ids = [var.linux_instances.security_group_id]
  key_name               = var.linux_instances.key_name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
    encrypted             = true
  }

  monitoring = true

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-linux-${count.index + 1}"
      OS   = "linux"
    }
  )
}

resource "aws_instance" "windows" {
  count = var.windows_instances.count

  ami                    = data.aws_ami.windows.id
  instance_type          = var.windows_instances.instance_type
  subnet_id              = var.windows_instances.subnet_id
  vpc_security_group_ids = [var.windows_instances.security_group_id]

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
    encrypted             = true
  }

  monitoring = true

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-windows-${count.index + 1}"
      OS   = "windows"
    }
  )
}
