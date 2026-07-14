# Production environment configuration

environment  = "prod"
project_name = "stratus"
owner_email  = "134101309+muhamm-ad@users.noreply.github.com"

# AWS
aws_region   = "us-east-1"
aws_vpc_cidr = "10.0.0.0/16"
enable_aws   = true

# Azure
azure_location  = "eastus"
azure_vnet_cidr = "10.1.0.0/16"
enable_azure    = false

# GCP
# gcp_project_id   empty by default
gcp_region       = "us-central1"
gcp_network_cidr = "10.2.0.0/16"
enable_gcp       = false

# VM Configuration
linux_vm_count   = 1
windows_vm_count = 1

linux_instance_type = {
  aws   = "t3.large"
  azure = "Standard_D2s_v3"
  gcp   = "n1-standard-2"
}

windows_instance_type = {
  aws   = "t3.large"
  azure = "Standard_D2s_v3"
  gcp   = "n1-standard-2"
}

# SSH/RDP Credentials
ssh_public_key_path    = "../keys/stratus-provinfra.pub"
windows_admin_username = "azureuser"
# Set windows_admin_password via env var: export TF_VAR_windows_admin_password='MyP@ssw0rd123'

additional_tags = {
}
