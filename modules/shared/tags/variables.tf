variable "environment" {
  type = string
}

variable "project_name" {
  type = string
}

variable "owner_email" {
  type = string
}

variable "cost_center" {
  type = string
}

variable "additional_tags" {
  type    = map(string)
  default = {}
}
