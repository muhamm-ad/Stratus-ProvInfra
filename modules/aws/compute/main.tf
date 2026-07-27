terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  userdata_dir = "${path.module}/../../shared/userdata"
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
    name = "name"
    # values = ["Windows_Server-2022-English-Core-*"]
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }
}

resource "aws_instance" "linux" {
  count = try(var.linux_instances.count, 0)

  ami                    = data.aws_ssm_parameter.linux[0].value
  instance_type          = try(var.linux_instances.instance_type, null)
  subnet_id              = try(var.linux_instances.subnet_id, null)
  vpc_security_group_ids = try([var.linux_instances.security_group_id], [])
  monitoring             = true
  root_block_device {
    volume_type           = var.linux_instances.disk.type
    volume_size           = var.linux_instances.disk.size
    delete_on_termination = true
    encrypted             = true
  }

  key_name = try(var.linux_instances.key_name, null)
  user_data = templatefile("${local.userdata_dir}/linux-userdata.yaml", {
    username      = coalesce(try(var.linux_instances.username, null), "")
    password_hash = coalesce(try(var.linux_instances.password_hash, null), "")
    extra         = coalesce(try(var.linux_instances.user_data, null), "")
  })
  lifecycle {
    ignore_changes = [user_data]
  }

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
  monitoring             = true
  root_block_device {
    volume_type           = var.windows_instances.disk.type
    volume_size           = var.windows_instances.disk.size
    delete_on_termination = true
    encrypted             = true
  }

  key_name = try(var.windows_instances.key_name, null)
  user_data = format("<powershell>\n%s\n</powershell>", templatefile("${local.userdata_dir}/win-userdata.ps1", {
    username           = coalesce(try(var.windows_instances.username, null), "")
    password_to_change = coalesce(try(var.windows_instances.password_to_change, null), "")
    extra              = coalesce(try(var.windows_instances.user_data, null), "")
  }))
  lifecycle {
    ignore_changes = [user_data]
  }

  tags = merge(
    var.tags,
    {
      Name              = "${var.name_prefix}_windows_${count.index + 1}"
      OS                = "windows"
      OSDefaultUsername = "Administrator"
    }
  )
}
