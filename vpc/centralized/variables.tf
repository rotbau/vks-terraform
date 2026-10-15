variable "nsx_manager_host" {
  type        = string
  description = "FQDN or IP of the NSX Manager"
}

variable "nsx_username" {
  type        = string
  default     = "admin"
}

variable "nsx_password" {
  type        = string
  sensitive   = true
}

variable "nsx_project_name" {
  type        = string
  description = "The NSX Project name within the Org"
}

variable "existing_connectivity_profile_name" {
  type        = string
  description = "Display name of the existing VPC Connectivity Profile used by VCFA"
}

variable "vpc_name" {
  type        = string
  default     = "vks-workload-vpc"
}

variable "vpc_short_id" {
  type        = string
  description = "Short identifier (alphanumeric, max 8 chars, e.g. vksvpc01)"
}

variable "vpc_private_ip_blocks" {
  type        = list(string)
  default     = ["10.150.0.0/16"]
  description = "CIDR block allocated to the VPC; VKS/Supervisor will carve node/pod networks from this range"
}