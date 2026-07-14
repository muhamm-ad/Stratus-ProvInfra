variable "name_prefix" {
  description = "Name prefix for all resources"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "cidr_block must be a valid IPv4 CIDR"
  }
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "subnet_configs" {
  description = "Subnet configurations keyed by enabled operating system"
  type = map(object({
    cidr = string
    az   = string
  }))

  validation {
    condition     = alltrue([for config in values(var.subnet_configs) : can(cidrhost(config.cidr, 0))])
    error_message = "All subnet CIDRs must be valid IPv4 CIDR blocks"
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
