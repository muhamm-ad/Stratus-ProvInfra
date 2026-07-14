variable "name_prefix" {
  type = string
}

variable "linux_instances" {
  type = object({
    count             = number
    instance_type     = string
    subnet_id         = string
    security_group_id = string
    key_name          = string
    user_data         = string
  })
}

variable "windows_instances" {
  type = object({
    count             = number
    instance_type     = string
    subnet_id         = string
    security_group_id = string
    key_name          = string
    user_data         = string
  })
}

variable "tags" {
  type = map(string)
}
