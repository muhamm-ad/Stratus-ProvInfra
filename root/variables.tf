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

variable "cloud_providers" {
  description = "Cloud provider configurations. Include only the providers you want to deploy."
  type = object({
    aws = optional(object({
      region       = string
      access_key   = string
      secret_key   = string
      access_token = string
      vpc_cidr     = string
    }))
    azure = optional(object({
      resource_group_name = string
      location            = string
      vnet_cidr           = string
    }))
    gcp = optional(object({
      project_id   = string
      region       = string
      network_cidr = string
    }))
  })

  validation {
    condition     = var.cloud_providers.aws != null || var.cloud_providers.azure != null || var.cloud_providers.gcp != null
    error_message = "providers must include at least one of aws, azure, or gcp"
  }
}

variable "instances" {
  description = "Instance configurations. Include only the operating systems you want to deploy."
  type = object({
    linux = optional(object({
      count = number
      instance_type = object({
        aws   = string
        azure = string
        gcp   = string
      })
      cidr = object({
        aws   = string
        azure = string
        gcp   = string
      })
    }))
    windows = optional(object({
      count = number
      instance_type = object({
        aws   = string
        azure = string
        gcp   = string
      })
      cidr = object({
        aws   = string
        azure = string
        gcp   = string
      })
    }))
  })
  default = {}

  validation {
    condition = (
      try(var.instances.linux.count >= 0, true) &&
      try(var.instances.windows.count >= 0, true)
    )
    error_message = "Instance counts must be zero or greater."
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
