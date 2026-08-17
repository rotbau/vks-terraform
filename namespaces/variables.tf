# ==========================================
# Authentication Variables
# ==========================================

variable "vsphere_user" {
  type        = string
  description = "The username for vCenter API authentication."
}

variable "vsphere_password" {
  type        = string
  sensitive   = true
  description = "The password for vCenter API authentication."
}

variable "vsphere_server" {
  type        = string
  description = "The FQDN or IP address of the vCenter server."
}

# ==========================================
# Namespace Configuration Variables
# ==========================================

variable "namespace_name" {
  type        = string
  description = "The name of the vSphere namespace to create."
}

variable "supervisor_id" {
  type        = string
  description = "The UUID of the vSphere Supervisor Cluster."
}

#variable "content_library_id" {
#  type        = string
#  description = "The UUID of the Content Library housing Tanzu Kubernetes releases."
#}

variable "vm_classes" {
  type        = list(string)
  description = "List of VM class names allowed in the namespace (e.g., best-effort-small)."
}

variable "storage_policy_ids" {
  type        = list(string)
  description = "List of Storage Policy UUIDs assigned to the namespace."
}