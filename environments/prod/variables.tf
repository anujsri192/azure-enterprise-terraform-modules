variable "environment" {
  description = "Target deployment environment (e.g. prod, uat, dev)."
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["prod", "uat", "dev", "staging"], var.environment)
    error_message = "environment must be one of: prod, uat, dev, staging."
  }
}

variable "location" {
  description = "Primary Azure region for all workloads."
  type        = string
  default     = "eastus"
}

variable "project_name" {
  description = "Enterprise project identifier prefix."
  type        = string
  default     = "enterprise-core"
}

variable "vnet_address_space" {
  description = "CIDR range for the Virtual Network."
  type        = list(string)
  default     = ["10.100.0.0/16"]
}

variable "subnets" {
  description = "Subnet definitions for the Virtual Network."
  type = map(object({
    address_prefixes                              = list(string)
    service_endpoints                             = optional(list(string), [])
    private_endpoint_network_policies_enabled     = optional(bool, true)
    private_link_service_network_policies_enabled = optional(bool, true)
    delegations = optional(list(object({
      name         = string
      service_name = string
      actions      = list(string)
    })), [])
    nsg_key        = optional(string, null)
    route_table_id = optional(string, null)
  }))
}

variable "network_security_groups" {
  description = "Network Security Groups configuration with dynamic security rule maps."
  type = map(object({
    name = string
    security_rules = list(object({
      name                         = string
      priority                     = number
      direction                    = string
      access                       = string
      protocol                     = string
      source_port_range            = optional(string)
      source_port_ranges           = optional(list(string))
      destination_port_range       = optional(string)
      destination_port_ranges      = optional(list(string))
      source_address_prefix        = optional(string)
      source_address_prefixes      = optional(list(string))
      destination_address_prefix   = optional(string)
      destination_address_prefixes = optional(list(string))
      description                  = optional(string)
    }))
  }))
}

variable "allowed_admin_ip_ranges" {
  description = "List of public IP CIDR ranges authorized to access Key Vault and management endpoints."
  type        = list(string)
  default     = []
}

variable "common_tags" {
  description = "Standard corporate enterprise tags applied across all resources."
  type        = map(string)
  default = {
    Environment = "Production"
    ManagedBy   = "Terraform"
    CostCenter  = "CC-FINOPS-1042"
    Owner       = "Anuj Srivastava"
    Compliance  = "NIST-800-53"
  }
}
