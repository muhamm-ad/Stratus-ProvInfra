# Production environment configuration
# Usage: terraform apply -var-file=../env/prod.tfvars

environment  = "prod"
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
  aws   = "t3.large"
  azure = "Standard_D2s_v3"
  gcp   = "n1-standard-2"
}

windows_instance_type = {
  aws   = "t3.large"
  azure = "Standard_D2s_v3"
  gcp   = "n1-standard-2"
}

windows_admin_username = "azureuser"

additional_tags = {
  Environment = "production"
  CostCenter  = "engineering"
}
