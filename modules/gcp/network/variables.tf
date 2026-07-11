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
  type = map(object({
    cidr = string
  }))
}

variable "tags" {
  type = map(string)
}
