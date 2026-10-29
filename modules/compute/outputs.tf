output "virtual_machines" {
  description = "Map of created virtual machine details."
  value = {
    for k, v in azurerm_linux_virtual_machine.this : k => {
      id                   = v.id
      name                 = v.name
      principal_id         = try(v.identity[0].principal_id, null)
      private_ip_address   = azurerm_network_interface.this[k].private_ip_address
      network_interface_id = azurerm_network_interface.this[k].id
    }
  }
}

output "vm_ids" {
  description = "Map of virtual machine keys to their resource IDs."
  value       = { for k, v in azurerm_linux_virtual_machine.this : k => v.id }
}

output "vm_principal_ids" {
  description = "Map of VM keys to their Managed Identity Principal IDs (for RBAC assignments)."
  value = {
    for k, v in azurerm_linux_virtual_machine.this : k => try(v.identity[0].principal_id, null)
    if try(v.identity[0].principal_id, null) != null
  }
}

output "network_interface_ids" {
  description = "Map of VM keys to their Network Interface IDs."
  value       = { for k, v in azurerm_network_interface.this : k => v.id }
}
