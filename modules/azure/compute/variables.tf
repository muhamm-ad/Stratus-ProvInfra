variable "name_prefix" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "linux_instances" {
  description = "Linux instance configuration. Null disables Linux instances."
  type = object({
    count                     = number
    vm_size                   = string
    subnet_id                 = string
    network_security_group_id = string
    public_ip_ids             = list(string)
    username                  = optional(string, "stratus")
    password_hash             = optional(string, "")
  })
  default = null
}

variable "windows_instances" {
  description = "Windows instance configuration. Null disables Windows instances."
  type = object({
    count                     = number
    vm_size                   = string
    subnet_id                 = string
    network_security_group_id = string
    username                  = optional(string, "stratus")
    password_to_change        = optional(string, "Stratus@123")
  })
  default   = null
  sensitive = true
}

variable "tags" {
  type = map(string)
}
