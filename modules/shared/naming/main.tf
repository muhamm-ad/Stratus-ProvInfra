locals {
  # Base prefix used for all resources
  name_prefix = "${var.environment}-${var.project_name}"

  # Provider-specific prefixes (some providers have naming restrictions)
  aws_prefix   = local.name_prefix
  azure_prefix = local.name_prefix
  gcp_prefix   = replace(local.name_prefix, "-", "_")
}

locals {
  linux_names = [
    for i in range(1, var.linux_count + 1) :
    "${local.name_prefix}-linux-${i}"
  ]

  windows_names = [
    for i in range(1, var.windows_count + 1) :
    "${local.name_prefix}-windows-${i}"
  ]
}

locals {
  vpc_name              = "${local.name_prefix}-vpc"
  subnet_linux_name     = "${local.name_prefix}-subnet-linux"
  subnet_windows_name   = "${local.name_prefix}-subnet-windows"
  nat_gateway_name      = "${local.name_prefix}-nat-gw"
  internet_gateway_name = "${local.name_prefix}-igw"
  security_group_name   = "${local.name_prefix}-sg"
  network_sg_name       = "${local.name_prefix}-nsg"
}

locals {
  ssh_key_name = "${local.name_prefix}-key"
  cert_name    = "${local.name_prefix}-cert"
}
