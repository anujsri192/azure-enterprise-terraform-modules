variable "resource_group_name" {
  description = "The name of the resource group where Key Vault is provisioned."
  type        = string
}

variable "location" {
  description = "Azure region for the Key Vault."
  type        = string
}

variable "key_vault_name" {
  description = "Name of the Azure Key Vault. Must be globally unique, 3-24 alphanumerics and hyphens."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{3,24}$", var.key_vault_name))
    error_message = "Key Vault name must be between 3 and 24 characters long and contain only alphanumeric characters and hyphens."
  }
}

variable "sku_name" {
  description = "SKU for the Key Vault. Allowed values: standard, premium."
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "sku_name must be either 'standard' or 'premium'."
  }
}

variable "soft_delete_retention_days" {
  description = "Number of days that items should be retained once soft-deleted. Between 7 and 90."
  type        = number
  default     = 90
}

variable "purge_protection_enabled" {
  description = "Is purge protection enabled for this Key Vault? Required for Zero-Trust enterprise security."
  type        = bool
  default     = true
}

variable "enable_rbac_authorization" {
  description = "Specify whether Azure Key Vault uses Role Based Access Control (RBAC) for authorization."
  type        = bool
  default     = false
}

variable "enabled_for_disk_encryption" {
  description = "Boolean flag to specify whether Azure Disk Encryption is permitted to retrieve secrets from the vault."
  type        = bool
  default     = true
}

variable "enabled_for_deployment" {
  description = "Boolean flag to specify whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets."
  type        = bool
  default     = true
}

variable "enabled_for_template_deployment" {
  description = "Boolean flag to specify whether Azure Resource Manager is permitted to retrieve secrets from the key vault."
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Whether public network access is allowed for this Key Vault."
  type        = bool
  default     = true
}

variable "network_acls" {
  description = <<EOF
Network ACL configuration object for the Key Vault.
When provided, uses a dynamic block to apply firewall and VNet rules.
EOF
  type = object({
    bypass                     = string
    default_action             = string
    ip_rules                   = optional(list(string), [])
    virtual_network_subnet_ids = optional(list(string), [])
  })
  default = null
}

variable "access_policies" {
  description = <<EOF
Map of access policies to create for the Key Vault.
Key is a unique descriptive name for the policy.
Value contains tenant_id, object_id, and permission lists.
EOF
  type = map(object({
    tenant_id               = string
    object_id               = string
    key_permissions         = optional(list(string), [])
    secret_permissions      = optional(list(string), [])
    certificate_permissions = optional(list(string), [])
    storage_permissions     = optional(list(string), [])
  }))
  default = {}
}

variable "secrets" {
  description = <<EOF
Map of secrets to store in the Key Vault.
Key is the secret name.
Value is an object with value, content_type, and optional tags.
EOF
  type = map(object({
    value        = string
    content_type = optional(string, "text/plain")
    tags         = optional(map(string), {})
  }))
  default = {}
}

variable "keys" {
  description = <<EOF
Map of cryptographic keys to generate in Key Vault (e.g. for Customer-Managed Key disk encryption).
EOF
  type = map(object({
    key_type = string
    key_size = number
    key_opts = list(string)
  }))
  default = {}
}

variable "private_endpoint" {
  description = <<EOF
Optional configuration for provisioning a private endpoint for the Key Vault.
EOF
  type = object({
    enabled             = bool
    subnet_id           = string
    private_dns_zone_id = optional(string)
  })
  default = null
}

variable "tags" {
  description = "Tags applied to all Key Vault resources."
  type        = map(string)
  default     = {}
}

