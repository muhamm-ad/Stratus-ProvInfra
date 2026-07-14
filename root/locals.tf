locals {
  # Naming prefix (used across all providers)
  name_prefix = "${var.environment}_${var.project_name}"

  # Common tags applied to all resources
  common_tags = merge(
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform"
      CreatedDate = formatdate("YYYY-MM-DD", timestamp())
      Owner       = var.owner_email
    },
    var.additional_tags
  )

  # CIDR subnetting (for consistency across regions)
  # AWS: 10.0.0.0/16 → 10.0.1.0/24, 10.0.2.0/24
  # Azure: 10.1.0.0/16 → 10.1.1.0/24, 10.1.2.0/24
  # GCP: 10.2.0.0/16 → 10.2.1.0/24, 10.2.2.0/24
  aws_subnet_cidr_linux   = "10.0.1.0/24"
  aws_subnet_cidr_windows = "10.0.2.0/24"

  azure_subnet_cidr_linux   = "10.1.1.0/24"
  azure_subnet_cidr_windows = "10.1.2.0/24"

  gcp_subnet_cidr_linux   = "10.2.1.0/24"
  gcp_subnet_cidr_windows = "10.2.2.0/24"

  # VM sizing based on environment
  vm_type_map = {
    dev = {
      linux_instance_type   = var.linux_instance_type
      windows_instance_type = var.windows_instance_type
    }
    prod = {
      linux_instance_type   = var.linux_instance_type
      windows_instance_type = var.windows_instance_type
    }
  }
}
