variable "allow_ssh_from_cidrs" {
  description = "CIDR blocks allowed SSH access"
  type        = list(string)
  default     = null
}

variable "allow_rdp_from_cidrs" {
  description = "CIDR blocks allowed RDP access"
  type        = list(string)
  default     = null
}

variable "allow_internal_traffic" {
  description = "Allow intra-VPC communication"
  type        = bool
  default     = true
}
