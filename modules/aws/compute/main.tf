terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

data "aws_ssm_parameter" "linux" {
  count = var.linux_instances != null ? 1 : 0
  name  = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

data "aws_ami" "windows" {
  count       = var.windows_instances != null ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Core-*"]
  }
}

resource "aws_instance" "linux" {
  count = try(var.linux_instances.count, 0)

  ami                    = data.aws_ssm_parameter.linux[0].value
  instance_type          = try(var.linux_instances.instance_type, null)
  subnet_id              = try(var.linux_instances.subnet_id, null)
  vpc_security_group_ids = try([var.linux_instances.security_group_id], [])
  key_name               = try(var.linux_instances.key_name, null)
  user_data              = try(var.linux_instances.user_data, null)

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
      Name              = "${var.name_prefix}_linux_${count.index + 1}"
      OS                = "linux"
      OSDefaultUsername = "ubuntu"
    }
  )
}

resource "aws_instance" "windows" {
  count = try(var.windows_instances.count, 0)

  ami                    = data.aws_ami.windows[0].id
  instance_type          = try(var.windows_instances.instance_type, null)
  subnet_id              = try(var.windows_instances.subnet_id, null)
  vpc_security_group_ids = try([var.windows_instances.security_group_id], [])
  key_name               = try(var.windows_instances.key_name, null)
  user_data              = try(var.windows_instances.user_data, null)

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
      Name              = "${var.name_prefix}_windows_${count.index + 1}"
      OS                = "windows"
      OSDefaultUsername = "Administrator"
    }
  )
}
