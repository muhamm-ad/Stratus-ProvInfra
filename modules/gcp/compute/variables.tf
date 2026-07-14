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
  description = "Linux instance configuration. Null disables Linux instances."
  type = object({
    count        = number
    machine_type = string
    subnet_name  = string
  })
  default = null
}

variable "windows_instances" {
  description = "Windows instance configuration. Null disables Windows instances."
  type = object({
    count          = number
    machine_type   = string
    subnet_name    = string
    admin_username = string
    admin_password = string
  })
  default   = null
  sensitive = true
}

variable "tags" {
  type = map(string)
}
