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
# same env/<environment>.tfvars file - this root only ever reads the `aws`
# slice, but the type has to accept azure/gcp too for that file to validate.
variable "cloud_providers" {
  description = "Cloud provider configurations. Include only the providers you want to deploy."
  type        = map(any)

  validation {
    condition     = var.cloud_providers.aws != null
    error_message = "root/aws requires cloud_providers.aws to be set"
  }
}

variable "instances" {
  description = "Instance configurations. Include only the operating systems you want to deploy."
  type = object({
    linux = optional(object({
      count         = number
      instance_type = map(string)
      cidr          = map(string)
      disk          = map(any)
      script        = optional(string)
      username      = optional(string, "")
      password_hash = optional(string, "")
    }))
    windows = optional(object({
      count              = number
      instance_type      = map(string)
      cidr               = map(string)
      disk               = map(any)
      script             = optional(string)
      username           = optional(string, "")
      password_to_change = optional(string, "")
    }))
  })
  default = {}
  # sensitive = true

  validation {
    condition = (
      try(var.instances.linux.count >= 0, true) &&
      try(var.instances.windows.count >= 0, true)
    )
    error_message = "Instance counts must be zero or greater."
  }
}

# Tagging
variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
