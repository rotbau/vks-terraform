resource "vsphere_namespace" "example" {
  name       = var.namespace_name
  supervisor = var.supervisor_id

  vm_service {
    vm_classes = var.vm_classes
  }

  storage_policies = var.storage_policy_ids
}