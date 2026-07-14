variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be dev or prod"
  }
}

variable "project_name" {
  description = "Project name for naming convention"
  type        = string
  default     = "stratus"

  validation {
    condition     = length(var.project_name) <= 20 && can(regex("^[a-z][a-z0-9-]*$", var.project_name))
    error_message = "project_name must start with lowercase letter and contain only lowercase letters, numbers, and hyphens"
  }
}

variable "owner_email" {
  description = "Owner email for tagging and notifications"
  type        = string
  default     = "devops@example.com"

  validation {
    condition     = can(regex("^[^@]+@[^@]+$", var.owner_email))
    error_message = "owner_email must be a valid email address"
  }
}

# AWS Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_vpc_cidr" {
  description = "CIDR block for AWS VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.aws_vpc_cidr, 0))
    error_message = "aws_vpc_cidr must be a valid IPv4 CIDR"
  }
}

# Azure Variables
variable "azure_resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = ""
  # If empty, will be computed as ${environment}-${project_name}-rg
}

variable "azure_location" {
  description = "Azure region/location"
  type        = string
  default     = "eastus"
}

variable "azure_vnet_cidr" {
  description = "CIDR block for Azure VNet"
  type        = string
  default     = "10.1.0.0/16"

  validation {
    condition     = can(cidrhost(var.azure_vnet_cidr, 0))
    error_message = "azure_vnet_cidr must be a valid IPv4 CIDR"
  }
}

# GCP Variables
variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
  default     = ""

  validation {
    condition     = var.gcp_project_id == "" || can(regex("^[a-z][a-z0-9-]{5,29}$", var.gcp_project_id))
    error_message = "gcp_project_id must be empty or match GCP project ID format"
  }
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "gcp_network_cidr" {
  description = "CIDR block for GCP VPC"
  type        = string
  default     = "10.2.0.0/16"

  validation {
    condition     = can(cidrhost(var.gcp_network_cidr, 0))
    error_message = "gcp_network_cidr must be a valid IPv4 CIDR"
  }
}

# VM Configuration
variable "linux_vm_count" {
  description = "Number of Linux VMs per provider"
  type        = number
  default     = 2

  validation {
    condition     = var.linux_vm_count > 0 && var.linux_vm_count <= 5
    error_message = "linux_vm_count must be between 1 and 5"
  }
}

variable "windows_vm_count" {
  description = "Number of Windows VMs per provider"
  type        = number
  default     = 2

  validation {
    condition     = var.windows_vm_count > 0 && var.windows_vm_count <= 5
    error_message = "windows_vm_count must be between 1 and 5"
  }
}

variable "linux_instance_type" {
  description = "Instance type map for Linux VMs"
  type = object({
    aws   = string
    azure = string
    gcp   = string
  })
  default = {
    aws   = "t3.micro"
    azure = "Standard_B1s"
    gcp   = "e2-micro"
  }
}

variable "windows_instance_type" {
  description = "Instance type map for Windows VMs"
  type = object({
    aws   = string
    azure = string
    gcp   = string
  })
  default = {
    aws   = "t3.small"
    azure = "Standard_B2s"
    gcp   = "e2-small"
  }
}

# SSH Key Configuration
variable "ssh_public_key_path" {
  description = "Path to SSH public key for Linux VMs (AWS)"
  type        = string
  default     = "../keys/stratus-provinfra.pub"
}

# RDP Windows Admin Password (Azure, GCP)
variable "windows_admin_username" {
  description = "Windows admin username"
  type        = string
  default     = "azureuser"
}

variable "windows_admin_password" {
  description = "Windows admin password (set via env var TF_VAR_windows_admin_password or tfvars)"
  type        = string
  sensitive   = true
  default     = ""

  validation {
    condition     = var.windows_admin_password == "" || (length(var.windows_admin_password) >= 12)
    error_message = "windows_admin_password must be at least 12 characters if set"
  }
}

# Enable/Disable per-provider deployment
variable "enable_aws" {
  description = "Enable AWS provider and resources"
  type        = bool
  default     = true
}

variable "enable_azure" {
  description = "Enable Azure provider and resources"
  type        = bool
  default     = true
}

variable "enable_gcp" {
  description = "Enable GCP provider and resources"
  type        = bool
  default     = true
}

# Tagging
variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
