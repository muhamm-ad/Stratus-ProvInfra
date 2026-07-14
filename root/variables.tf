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

variable "providers" {
  description = "Cloud provider configurations"
  type        = map(any)
  default = {
    aws = {
      region       = "us-east-1"
      access_key   = ""
      secret_key   = ""
      access_token = ""
      vpc_cidr     = "10.0.0.0/16"
    }
    azure = {
      resource_group_name = ""
      location            = "eastus"
      vnet_cidr           = "10.1.0.0/16"
    }
    gcp = {
      project_id   = ""
      region       = "us-central1"
      network_cidr = "10.2.0.0/16"
    }
  }

  validation {
    condition     = contains(keys(var.providers), "aws") || contains(keys(var.providers), "azure") || contains(keys(var.providers), "gcp")
    error_message = "providers must contain aws, azure, or gcp"
  }
}

variable "instances" {
  description = "Instances configurations"
  type        = map(any)
  default = {
    linux = {
      count = 1
      instance_type = {
        aws   = "t3.micro"
        azure = "Standard_B1s"
        gcp   = "e2-micro"
      }
      cidr = {
        aws   = "10.0.1.0/24"
        azure = "10.1.1.0/24"
        gcp   = "10.2.1.0/24"
      }
    }
    windows = {
      count = 1
      instance_type = {
        aws   = "t3.small"
        azure = "Standard_B2s"
        gcp   = "e2-small"
      }
      cidr = {
        aws   = "10.0.2.0/24"
        azure = "10.1.2.0/24"
        gcp   = "10.2.2.0/24"
      }
    }
  }
  validation {
    condition     = contains(keys(var.instances), "linux") && contains(keys(var.instances), "windows")
    error_message = "instances must contain linux and windows"
  }
  validation {
    condition     = contains(keys(var.instances.linux), "count") && contains(keys(var.instances.linux), "instance_type") && contains(keys(var.instances.windows), "count") && contains(keys(var.instances.windows), "instance_type")
    error_message = "instances must contain count and instance_type"
  }
}

variable "security" {
  description = "Security configurations"
  type        = map(any)
  default = {
    ssh = {
      public_key_path = "../keys/stratus-provinfra.pub"
    }
    windows = {
      username = "azureuser"
    }
  }
}

# Tagging
variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
