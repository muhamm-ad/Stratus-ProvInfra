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
    network_interface_ids     = list(string)
    key_name                  = optional(string, null)
    user_data                 = optional(string)
    username                  = optional(string, "stratus")
    password_hash             = optional(string, "")
    disk = {
      size_gb = optional(number, 32)
      type = optional(string, "Premium_LRS")
      caching = optional(string, "ReadWrite")
    }

  })
  default = null
  sensitive = true
}

variable "windows_instances" {
  description = "Windows instance configuration. Null disables Windows instances."
  type = object({
    count                     = number
    vm_size                   = string
    subnet_id                 = string
    network_interface_ids     = list(string)
    key_name                  = optional(string, null)
    user_data                 = optional(string)
    username                  = optional(string, "stratus")
    password_to_change        = optional(string, "Stratus@123")
    disk = {
      size_gb = optional(number, 50)
      type = optional(string, "Premium_LRS")
      caching = optional(string, "ReadWrite")
    }
  })
  default   = null
  sensitive = true
}

variable "tags" {
  type = map(string)
}
