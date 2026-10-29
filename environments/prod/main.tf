/**
 * # Production Enterprise Infrastructure (Parent / Root Module)
 * 
 * Orchestrates child modules with end-to-end dependency chaining:
 * 1. Resource Group Module
 * 2. Monitoring & Log Analytics Workspace
 * 3. Enterprise Virtual Network with for_each subnets & dynamic NSG rules
 * 4. Hardened Azure Key Vault with dynamic network ACLs, secrets, CMK & Private Endpoint
 * 5. Compute Module with for_each VM instances & managed disk attachments
 * 6. Centralized Diagnostic Settings streaming telemetry to Log Analytics
 */

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  location    = var.location

  tags = merge(var.common_tags, {
    DeployedAt = "2026-10-29"
    Repository = "azure-enterprise-terraform-modules"
  })
}

# --------------------------------------------------------------------------------------------------
# Client configuration & Random helpers
# --------------------------------------------------------------------------------------------------
data "azurerm_client_config" "current" {}

resource "random_string" "kv_suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "random_password" "vm_admin_password" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_upper        = 4
  min_lower        = 4
  min_numeric      = 4
  min_special      = 4
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# --------------------------------------------------------------------------------------------------
# 1. Resource Group
# --------------------------------------------------------------------------------------------------
module "resource_group" {
  source = "../../modules/resource_group"

  name     = "rg-${local.name_prefix}"
  location = local.location
  tags     = local.tags
}

# --------------------------------------------------------------------------------------------------
# 2. Centralized Observability & Telemetry (Log Analytics Workspace)
# --------------------------------------------------------------------------------------------------
module "monitoring" {
  source = "../../modules/monitoring"

  workspace_name      = "law-${local.name_prefix}"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  sku                 = "PerGB2018"
  retention_in_days   = 90
  tags                = local.tags
}

# --------------------------------------------------------------------------------------------------
# 3. Enterprise Virtual Network & Subnets
# --------------------------------------------------------------------------------------------------
module "networking" {
  source = "../../modules/networking"

  vnet_name               = "vnet-${local.name_prefix}"
  resource_group_name     = module.resource_group.name
  location                = module.resource_group.location
  address_space           = var.vnet_address_space
  subnets                 = var.subnets
  network_security_groups = var.network_security_groups
  tags                    = local.tags
}

# --------------------------------------------------------------------------------------------------
# 4. Hardened Azure Key Vault (Zero-Trust Security, CMK & Private Endpoint)
# --------------------------------------------------------------------------------------------------
module "key_vault" {
  source = "../../modules/key_vault"

  key_vault_name             = "kv-${substr(var.project_name, 0, 10)}-${random_string.kv_suffix.result}"
  resource_group_name        = module.resource_group.name
  location                   = module.resource_group.location
  sku_name                   = "standard"
  soft_delete_retention_days = 90
  purge_protection_enabled   = true

  # Dynamic Network ACLs with IP whitelist and Subnet association
  network_acls = {
    bypass                     = "AzureServices"
    default_action             = "Allow" # Set to Deny in strict Private Link scenarios
    ip_rules                   = var.allowed_admin_ip_ranges
    virtual_network_subnet_ids = [module.networking.subnet_ids["snet-workloads"]]
  }

  # Terraform deployment principal access policy
  access_policies = {
    "terraform-spn" = {
      tenant_id               = data.azurerm_client_config.current.tenant_id
      object_id               = data.azurerm_client_config.current.object_id
      key_permissions         = ["Get", "List", "Create", "Delete", "Update", "Recover", "Purge", "GetRotationPolicy"]
      secret_permissions      = ["Get", "List", "Set", "Delete", "Recover", "Purge"]
      certificate_permissions = ["Get", "List", "Create", "Delete", "Recover", "Purge"]
    }
  }

  # Secrets populated directly via Key Vault module
  secrets = {
    "vm-admin-username" = {
      value        = "azureadmin"
      content_type = "text/plain"
      tags         = { Purpose = "VM Admin User" }
    }
    "vm-admin-password" = {
      value        = random_password.vm_admin_password.result
      content_type = "credentials/password"
      tags         = { Purpose = "VM Password Credential" }
    }
    "vm-ssh-private-key" = {
      value        = tls_private_key.ssh_key.private_key_pem
      content_type = "application/x-pem-file"
      tags         = { Purpose = "Private SSH Key for Bastion/Automation" }
    }
    "vm-ssh-public-key" = {
      value        = tls_private_key.ssh_key.public_key_openssh
      content_type = "text/plain"
      tags         = { Purpose = "Public SSH Key" }
    }
  }

  # Customer Managed Key (CMK) for Azure Disk Encryption
  keys = {
    "cmk-disk-encryption" = {
      key_type = "RSA"
      key_size = 4096
      key_opts = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]
    }
  }

  # Zero-Trust Private Endpoint inside private endpoints subnet
  private_endpoint = {
    enabled   = true
    subnet_id = module.networking.subnet_ids["snet-private-endpoints"]
  }

  tags = local.tags

  depends_on = [module.networking]
}

# --------------------------------------------------------------------------------------------------
# 5. Linux Virtual Machines (Using Key Vault Credentials)
# --------------------------------------------------------------------------------------------------
module "compute" {
  source = "../../modules/compute"

  resource_group_name = module.resource_group.name
  location            = module.resource_group.location

  virtual_machines = {
    "app-server-01" = {
      name                            = "vm-${local.name_prefix}-app-01"
      vm_size                         = "Standard_D2s_v5"
      admin_username                  = "azureadmin"
      admin_ssh_public_key            = tls_private_key.ssh_key.public_key_openssh
      disable_password_authentication = true
      subnet_id                       = module.networking.subnet_ids["snet-workloads"]
      os_disk_type                    = "Premium_LRS"
      os_disk_size_gb                 = 128
      identity_type                   = "SystemAssigned"
      data_disks = {
        "datadisk-01" = {
          size_gb = 128
          type    = "Premium_LRS"
          caching = "ReadWrite"
          lun     = 10
        }
      }
    }
    "app-server-02" = {
      name                            = "vm-${local.name_prefix}-app-02"
      vm_size                         = "Standard_D2s_v5"
      admin_username                  = "azureadmin"
      admin_ssh_public_key            = tls_private_key.ssh_key.public_key_openssh
      disable_password_authentication = true
      subnet_id                       = module.networking.subnet_ids["snet-workloads"]
      os_disk_type                    = "Premium_LRS"
      os_disk_size_gb                 = 128
      identity_type                   = "SystemAssigned"
      data_disks = {
        "datadisk-01" = {
          size_gb = 128
          type    = "Premium_LRS"
          caching = "ReadWrite"
          lun     = 10
        }
      }
    }
  }

  tags = local.tags

  depends_on = [module.key_vault, module.networking]
}

# --------------------------------------------------------------------------------------------------
# 6. Key Vault Diagnostic Settings to Log Analytics
# --------------------------------------------------------------------------------------------------
resource "azurerm_monitor_diagnostic_setting" "key_vault_telemetry" {
  name                       = "kv-${local.name_prefix}-telemetry"
  target_resource_id         = module.key_vault.id
  log_analytics_workspace_id = module.monitoring.workspace_id

  dynamic "enabled_log" {
    for_each = ["AuditEvent", "AzurePolicyEvaluationDetails"]
    content {
      category = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = ["AllMetrics"]
    content {
      category = metric.value
      enabled  = true
    }
  }
}

