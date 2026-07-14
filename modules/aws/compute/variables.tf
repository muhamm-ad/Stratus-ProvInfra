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
    key_name          = string
    user_data         = string
  })
  default = null
}

variable "windows_instances" {
  description = "Windows instance configuration. Null disables Windows instances."
  type = object({
    count             = number
    instance_type     = string
    subnet_id         = string
    security_group_id = string
    key_name          = string
    user_data         = string
  })
  default = null
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