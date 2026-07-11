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
  type = map(object({
    cidr = string
  }))
}

variable "tags" {
  type = map(string)
}
