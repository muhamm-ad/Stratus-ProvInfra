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
    user_data    = optional(string)
    username     = optional(string, "ubuntu")
    disk = optional(object({
      size = optional(number, 32)
      type = optional(string, "pd-ssd")
    }), {})
  })
  default   = null
  sensitive = true
}

variable "windows_instances" {
  description = "Windows instance configuration. Null disables Windows instances."
  type = object({
    count              = number
    machine_type       = string
    subnet_name        = string
    user_data          = optional(string)
    username           = optional(string, "stratus")
    password_to_change = optional(string, "Stratus@123")
    disk = optional(object({
      size = optional(number, 50)
      type = optional(string, "pd-ssd")
    }), {})
  })
  default   = null
  sensitive = true
}

variable "tags" {
  type = map(string)
}
