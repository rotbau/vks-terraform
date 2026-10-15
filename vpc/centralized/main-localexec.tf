terraform {
  required_version = ">= 1.5.0"
  required_providers {
    nsxt = {
      source  = "vmware/nsxt"
      version = "~> 3.12.0"
    }
  }
}

provider "nsxt" {
  host                 = var.nsx_manager_host
  username             = var.nsx_username
  password             = var.nsx_password
  allow_unverified_ssl = true
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

# Set to true for AVI Integration
  load_balancer_vpc_endpoint {
    enabled = false
  }
}

resource "nsxt_vpc_attachment" "vks_attachment" {
  display_name             = "${var.vpc_name}-attachment"
  parent_path              = nsxt_vpc.vks_vpc.path
  vpc_connectivity_profile = data.nsxt_vpc_connectivity_profile.existing_profile.path
}


# Enable Native NSX VPC Load Balancer via local-exec (Required for VKS compatibility)

resource "terraform_data" "vpc_native_lb" {
  # Stores connection details inside self.input for access during destroy
  input = {
    host       = var.nsx_manager_host
    user       = var.nsx_username
    pass       = var.nsx_password
    project_id = data.nsxt_policy_project.project.id
    vpc_id     = nsxt_vpc.vks_vpc.id
  }

  triggers_replace = [
    nsxt_vpc.vks_vpc.id
  ]

  # Create / Enable the Native VPC Load Balancer
  provisioner "local-exec" {
    command = <<-EOT
      curl -s -k -u '${self.input.user}:${self.input.pass}' \
        -X PUT "https://${self.input.host}/policy/api/v1/orgs/default/projects/${self.input.project_id}/vpcs/${self.input.vpc_id}/vpc-lbs/lb-1" \
        -H "Content-Type: application/json" \
        -d '{
          "resource_type": "LBService",
          "display_name": "lb-1",
          "enabled": true,
          "size": "SMALL"
        }'
    EOT
  }

  # Clean up the LB child object on destroy so NSX does not lock the VPC
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      curl -s -k -u '${self.input.user}:${self.input.pass}' \
        -X DELETE "https://${self.input.host}/policy/api/v1/orgs/default/projects/${self.input.project_id}/vpcs/${self.input.vpc_id}/vpc-lbs/lb-1"
    EOT
  }

  depends_on = [
    nsxt_vpc_attachment.vks_attachment
  ]
}
