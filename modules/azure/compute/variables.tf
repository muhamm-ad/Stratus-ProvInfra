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
    admin_username            = string
    admin_password            = string
  })
  default   = null
  sensitive = true
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key for Linux VMs"
  type        = string
  default     = "../keys/stratus-terraform.pub"
}

variable "tags" {
  type = map(string)
}
