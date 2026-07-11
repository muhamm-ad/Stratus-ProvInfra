locals {
  default_ssh_cidrs = ["0.0.0.0/0"]
  default_rdp_cidrs = ["0.0.0.0/0"]

  ssh_rules = {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allow_ssh_from_cidrs != null ? var.allow_ssh_from_cidrs : local.default_ssh_cidrs
  }

  rdp_rules = {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = var.allow_rdp_from_cidrs != null ? var.allow_rdp_from_cidrs : local.default_rdp_cidrs
  }

  egress_all = {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
