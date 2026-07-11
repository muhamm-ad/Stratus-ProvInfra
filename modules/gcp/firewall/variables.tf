variable "name_prefix" {
  type = string
}

variable "project_id" {
  type = string
}

variable "network_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
