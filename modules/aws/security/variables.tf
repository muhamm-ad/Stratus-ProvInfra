variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "ssh_key_name" {
  type = string
}

variable "ssh_public_key_path" {
  type = string
}

variable "tags" {
  type = map(string)
}
