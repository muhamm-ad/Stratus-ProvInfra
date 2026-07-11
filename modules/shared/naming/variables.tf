variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "linux_count" {
  description = "Number of Linux instances"
  type        = number
  default     = 2
}

variable "windows_count" {
  description = "Number of Windows instances"
  type        = number
  default     = 2
}
