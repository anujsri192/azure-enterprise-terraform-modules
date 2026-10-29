output "vnet_id" {
  description = "The ID of the Virtual Network."
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "The name of the Virtual Network."
  value       = azurerm_virtual_network.this.name
}

output "vnet_address_space" {
  description = "The address space of the Virtual Network."
  value       = azurerm_virtual_network.this.address_space
}

output "subnets" {
  description = "Map of all provisioned subnets keyed by subnet name."
  value = {
    for k, v in azurerm_subnet.this : k => {
      id               = v.id
      name             = v.name
      address_prefixes = v.address_prefixes
    }
  }
}

output "subnet_ids" {
  description = "Map of subnet names to their respective resource IDs."
  value       = { for k, v in azurerm_subnet.this : k => v.id }
}

output "network_security_group_ids" {
  description = "Map of NSG keys to their respective resource IDs."
  value       = { for k, v in azurerm_network_security_group.this : k => v.id }
}

