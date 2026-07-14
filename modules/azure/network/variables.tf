variable "name_prefix" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "vnet_cidr" {
  type = string
}

variable "linux_count" {
  type    = number
  default = 2
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
