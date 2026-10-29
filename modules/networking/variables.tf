variable "resource_group_name" {
  description = "The name of the resource group in which to create the networking resources."
  type        = string
}

variable "location" {
  description = "The Azure region where the virtual network and subnets will be hosted."
  type        = string
}

variable "vnet_name" {
  description = "The name of the Virtual Network."
  type        = string
}

variable "address_space" {
  description = "The address space used by the Virtual Network (CIDR block)."
  type        = list(string)
  default     = ["10.100.0.0/16"]
}

variable "dns_servers" {
  description = "List of custom DNS servers IP addresses for the VNet. Null for default Azure DNS."
  type        = list(string)
  default     = null
}

variable "subnets" {
  description = <<EOF
Map of subnets to create within the Virtual Network.
Key is the subnet identifier/name.
Value is an object with:
- address_prefixes: CIDR range list
- service_endpoints: list of service endpoints
- private_endpoint_network_policies_enabled: boolean
- private_link_service_network_policies_enabled: boolean
- delegations: optional list of subnet delegation objects
- nsg_key: optional key of NSG to associate with this subnet
- route_table_id: optional route table resource ID to associate with this subnet
EOF
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
  description = <<EOF
Map of Network Security Groups with nested security rules.
Uses dynamic blocks to iterate over security rules.
EOF
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
  default = {}
}

variable "tags" {
  description = "Tags to be applied to all networking resources."
  type        = map(string)
  default     = {}
}

