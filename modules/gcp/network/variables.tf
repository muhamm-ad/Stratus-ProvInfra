variable "name_prefix" {
  type = string
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "network_cidr" {
  type    = string
  default = "10.2.0.0/16"
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
