# Development environment configuration
# Usage: terraform apply -var-file=../env/dev.tfvars

environment  = "dev"
project_name = "stratus"
cost_center  = "engineering"
owner_email  = "devops@example.com"

# AWS
aws_region   = "us-east-1"
aws_vpc_cidr = "10.0.0.0/16"
enable_aws   = true

# Azure
azure_location  = "eastus"
azure_vnet_cidr = "10.1.0.0/16"
enable_azure    = true

# GCP
gcp_region       = "us-central1"
gcp_network_cidr = "10.2.0.0/16"
enable_gcp       = true

# VM Configuration
linux_vm_count   = 2
windows_vm_count = 2

linux_instance_type = {
  aws   = "t3.micro"
  azure = "Standard_B1s"
  gcp   = "e2-micro"
}

windows_instance_type = {
  aws   = "t3.small"
  azure = "Standard_B2s"
  gcp   = "e2-small"
}

# SSH/RDP Credentials
windows_admin_username = "azureuser"
# Set windows_admin_password via env var: export TF_VAR_windows_admin_password='MyP@ssw0rd'

additional_tags = {
  Environment = "development"
  CostCenter  = "engineering"
  Managed     = "terraform"
}
