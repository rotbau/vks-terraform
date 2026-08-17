# vSphere Terraform Namespace Creation

This example is based on the vSphere Terraform provider to create a vSphere Namespace.  The vSphere Terraform provider is missing the capability to override vSphere namespace network configuration and assign RBAC.  This feature is in the VCFA terraform provider.

## Pre-requisites
1. Credentials assigned namespace owner / ability to create vSphere namespaces
2. Supervisor ID
```
# From vCenter you can run DCLI command or highlight supervisor cluster in vCenter UI to get supervisor ID
dcli com vmware vcenter namespacemanagement supervisors summary list
```
3. Storage Class ID
```
# From vCenter you can run DCLI command or highlight storage binary in vCenter UI to get storage class ID
dcli com vmware vcenter storage policies list
or
dcli com vmware vcenter namespacemanagement clusters get --cluster {supervisor domain ex domain-c9}
(Look for the ephemeral_storage_policy, image_storage, or master_storage_policy fields in the output)
```
## Create vSphere Namespace
1. Update required credentials, supervisor ID, storageclass ID, and namespace specific variables
2. `terraform init` if you need to initialize terraform
3. `terraform validate`
4. `terraform plan`
5. `terrafrom apply`