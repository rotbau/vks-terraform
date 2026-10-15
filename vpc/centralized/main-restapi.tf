terraform {
  required_version = ">= 1.5.0"
  required_providers {
    nsxt = {
      source  = "vmware/nsxt"
      version = "~> 3.12.0"
    }
    restapi = {
      source  = "Mastercard/restapi"
      version = "~> 1.19.0"
    }
  }
}

provider "nsxt" {
  host                 = var.nsx_manager_host
  username             = var.nsx_username
  password             = var.nsx_password
  allow_unverified_ssl = true
}

provider "restapi" {
  uri                  = "https://${var.nsx_manager_host}/policy/api/v1"
  username             = var.nsx_username
  password             = var.nsx_password
  insecure             = true
  write_returns_object = true
}

# Lookup Existing Connectivity Profile (for Centralized TGW)

data "nsxt_policy_project" "project" {
  display_name = var.nsx_project_name
}

data "nsxt_vpc_connectivity_profile" "existing_profile" {
  context {
    project_id = data.nsxt_policy_project.project.id
  }
  display_name = var.existing_connectivity_profile_name
}

# Create VPC and Attach Connectivity Profile (Centralized)

resource "nsxt_vpc" "vks_vpc" {
  context {
    project_id = data.nsxt_policy_project.project.id
  }
  display_name = var.vpc_name
  short_id     = var.vpc_short_id
  private_ips  = var.vpc_private_ip_blocks


# Change to true to enable AVI LB integration
  load_balancer_vpc_endpoint {
    enabled = false
  }
}

resource "nsxt_vpc_attachment" "vks_attachment" {
  display_name             = "${var.vpc_name}-attachment"
  parent_path              = nsxt_vpc.vks_vpc.path
  vpc_connectivity_profile = data.nsxt_vpc_connectivity_profile.existing_profile.path
}

# Enable Native NSX VPC Load Balancer via Mastercard RestAPI TF provider (Required for VKS compatibility)

locals {
  vpc_lb_id   = "lb-1"
  vpc_lb_path = "/orgs/default/projects/${data.nsxt_policy_project.project.id}/vpcs/${nsxt_vpc.vks_vpc.id}/vpc-lbs/${local.vpc_lb_id}"
}

resource "restapi_object" "vks_vpc_lb" {
  # Base collection path
  path          = "/orgs/default/projects/${data.nsxt_policy_project.project.id}/vpcs/${nsxt_vpc.vks_vpc.id}/vpc-lbs"

  # Explicitly target the individual object URI on creation
  create_path   = local.vpc_lb_path
  create_method = "PUT"

  # Ensure read/update/destroy point to the exact resource endpoint
  read_path      = local.vpc_lb_path
  update_path    = local.vpc_lb_path
  destroy_path   = local.vpc_lb_path
  destroy_method = "DELETE"

  object_id    = local.vpc_lb_id
  id_attribute = "id"

  data = jsonencode({
    id            = local.vpc_lb_id
    resource_type = "LBService"
    display_name  = local.vpc_lb_id
    enabled       = true
    size          = "SMALL"
  })

  depends_on = [
    nsxt_vpc_attachment.vks_attachment
  ]
}
