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

# Shared across root/aws, root/azure, root/gcp so all three can read the
# same env/<environment>.tfvars file - this root only ever reads the `gcp`
# slice, but the type has to accept aws/azure too for that file to validate.
variable "cloud_providers" {
  description = "Cloud provider configurations. Include only the providers you want to deploy."
  type        = map(any)

  validation {
    condition     = var.cloud_providers.gcp != null
    error_message = "root/gcp requires cloud_providers.gcp to be set"
  }
}

variable "instances" {
  description = "Instance configurations. Include only the operating systems you want to deploy."
  type = object({
    linux = optional(object({
      count         = number
      instance_type = map(string)
      cidr          = map(string)
    }))
    windows = optional(object({
      count         = number
      instance_type = map(string)
      cidr          = map(string)
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
