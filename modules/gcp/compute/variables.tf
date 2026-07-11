variable "name_prefix" {
  type = string
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "linux_instances" {
  type = object({
    count        = number
    machine_type = string
    subnet_name  = string
  })
}

variable "windows_instances" {
  type = object({
    count          = number
    machine_type   = string
    subnet_name    = string
    admin_username = string
    admin_password = string
  })
  sensitive = true
}

variable "tags" {
  type = map(string)
}
