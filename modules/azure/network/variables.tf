variable "name_prefix" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}


variable "network_security_group_ids" {
  type = object({
    linux   = string
    windows = string
  })
  default = {
    linux   = null
    windows = null
  }
}


variable "vnet_cidr" {
  type = string
}

variable "instances" {
  description = "Linux instance configuration. Null disables Linux instances."
  type = map(object({
    count = number
  }))
}

variable "subnet_configs" {
  description = "Subnet configurations keyed by enabled operating system"
  type = map(object({
    cidr = string
  }))

  validation {
    condition     = alltrue([for config in values(var.subnet_configs) : can(cidrhost(config.cidr, 0))])
    error_message = "All subnet CIDRs must be valid IPv4 CIDR blocks"
  }
}

variable "tags" {
  type = map(string)
}
