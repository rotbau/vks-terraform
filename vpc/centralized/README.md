# Provision VKS Compatible NSX VPCs with Native Load Balancing via Terraform

Deploy a VMware NSX Virtual Private Cloud (VPC) attached to an existing Centralized Transit Gateway (CTGW) and provisioned for vSphere Kubernetes Service (VKS) clusters.

When deploying VKS / Tanzu clusters using the built-in ClusterClass without VMware NSX Advanced Load Balancer (Avi), Tanzu's Cluster API (CAPI) admission webhook enforces that a native NSX Load Balancer must exist inside the target VPC namespace:

```text
admission webhook "capi.validating.tanzukubernetescluster.run.tanzu.vmware.com" denied the request: 
cluster can not be deployed with built-in cluster class in a VPC namespace without Load Balancer
```

Enabling `load_balancer_vpc_endpoint { enabled = true }` in the NSX Terraform provider only reserves IP space for Avi—it **does not** create the native load balancer service. Furthermore, native VPC load balancers (`/vpc-lbs/<lb-id>`) are not exposed in the NSX UI or supported as a resource in the `vmware/nsxt` Terraform provider.

This repository bridges that gap by deploying the VPC, attaching it to an existing Centralized Transit Gateway via a VPC Connectivity Profile, and creating the required native VPC Load Balancer service (`LBService`) using either:

1. **`Mastercard/restapi` Provider (Recommended):** Manages the LB lifecycle declaratively within Terraform state without shell dependencies.
2. **`local-exec` Provisioner:** Uses native Terraform lifecycle hooks and `curl` commands.

---

## Validated Environment

| Component | Version |
| :--- | :--- |
| **vCenter Server** | 9.1.0300+ |
| **vSphere Kubernetes Service (VKS)** | 3.7+ |
| **VMware NSX** | 9.1+ |
| **Terraform NSX-T Provider (`vmware/nsxt`)** | `~> 3.12.0` |
| **Terraform CLI** | `>= 1.5.0` |

---

## Prerequisites

Before deploying:
* Centralized Transit Gateway (CTGW): Must already exist in your NSX project/org.
* VPC Connectivity Profile: Must already exist and include:
  * An assigned **Transit Gateway**.
  * At least one **External IP Block** (required for egress NAT).
  * An assigned **Edge Cluster** under the Service Gateway (satisfies stateful service requirements like NAT and DHCP profiles).
  * **Default Outbound NAT / SNAT Enabled:** Required by VKS to allow private worker nodes to pull container images and reach vCenter.

---

## Repository Structure

```text
.
├── variables.tf                 # Variable declarations
├── terraform.tfvars.example     # Sample environment configuration
├── main-restapi.tf              # Option 1: Mastercard/restapi provider (Declarative)
└── main-localexec.tf            # Option 2: terraform_data with local-exec (curl)
```
---

## Quick Start

### 1. Select Your Implementation Method

Keep the `.tf` file for your preferred method and remove or rename the other:

* Option A: Declarative REST API (Recommended)
  ```bash
  mv main-restapi.tf main.tf
  rm -f main-localexec.tf
  ```

* Option B: Local Exec (`curl`)
  ```bash
  mv main-localexec.tf main.tf
  rm -f main-restapi.tf
  ```

### 2. Configure Variables

Create `terraform.tfvars` from the example:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Update `terraform.tfvars` with your environment values:

```hcl
# NSX Connection Details
nsx_manager_host = "nsx-manager.corp.local"
nsx_username     = "admin"
nsx_password     = "YourSecurePassword"

# NSX Project & Infrastructure Context
nsx_project_name                   = "org-test-dev"
existing_connectivity_profile_name = "Default VPC Connectivity Profile"

# VKS Workload VPC Settings
vpc_name              = "vks-cluster-01-vpc"
vpc_short_id          = "vks01vpc"           # Alphanumeric, max 8 chars
vpc_private_ip_blocks = ["10.150.0.0/16"]     # Subnet pool for VKS nodes/pods
```

### 3. Deploy the VPC

```bash
terraform init
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

### 4. Deploy VKS Cluster

1. In vCenter, navigate to **Workload Management** > **Namespaces**.
2. Create or select a namespace and map it to your newly created VPC (`vks-cluster-01-vpc`).
3. Deploy your Tanzu Kubernetes Cluster (TKC / ClusterClass) using the **Default Network** configuration.

---

## Teardown

To remove the Load Balancer and VPC:

```bash
terraform destroy
```

Both methods issue a `DELETE` call against `/policy/api/v1/.../vpc-lbs/lb-1` before deleting the VPC attachment, avoiding orphan object locks in NSX.