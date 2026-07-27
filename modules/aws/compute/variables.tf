variable "name_prefix" {
  type = string
}

variable "linux_instances" {
  description = "Linux instance configuration. Null disables Linux instances."
  type = object({
    count             = number
    instance_type     = string
    subnet_id         = string
    security_group_id = string
    key_name          = optional(string, null)
    user_data         = optional(string)
    username          = optional(string, "ubuntu")
    password_hash     = optional(string, "")
    disk = {
      size = optional(number, 40)
      type = optional(string, "gp3")
    }
  })
  default = null
  sensitive = true
}

variable "windows_instances" {
  description = "Windows instance configuration. Null disables Windows instances."
  type = object({
    count              = number
    instance_type      = string
    subnet_id          = string
    security_group_id  = string
    key_name           = optional(string, null)
    user_data          = optional(string)
    username           = optional(string, "stratus")
    password_to_change = optional(string, "Stratus@123")
    disk = {
      size = optional(number, 50)
      type = optional(string, "gp3")
    }
  })
  default = null
  sensitive = true
}

variable "tags" {
  type = map(string)
}


variable "os_default_username" {
  type = object({
    linux   = map(string)
    windows = map(string)
  })
  description = "The default username for the operating system"

  default = {
    linux = {
      ubuntu    = "ubuntu"
      centos    = "centos"
      redhat    = "redhat"
      fedora    = "fedora"
      debian    = "debian"
      archlinux = "archlinux"
    }
    windows = {
      french     = "Administrateur"
      english    = "Administrator"
      spanish    = "Administrador"
      german     = "Administrator"
      italian    = "Administrator"
      portuguese = "Administrador"
      russian    = "Administrator"
      chinese    = "Administrator"
      japanese   = "Administrator"
      korean     = "Administrator"
      arabic     = "Administrator"
    }
  }
}
