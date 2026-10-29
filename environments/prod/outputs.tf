output "resource_group_name" {
  description = "The name of the provisioned Resource Group."
  value       = module.resource_group.name
}

output "virtual_network_id" {
  description = "The ID of the Virtual Network."
  value       = module.networking.vnet_id
}

output "subnet_ids" {
  description = "Map of all provisioned subnet IDs."
  value       = module.networking.subnet_ids
}

output "key_vault_name" {
  description = "The name of the Azure Key Vault."
  value       = module.key_vault.name
}

output "key_vault_id" {
  description = "The resource ID of the Azure Key Vault."
  value       = module.key_vault.id
}

output "key_vault_uri" {
  description = "The URI of the Azure Key Vault."
  value       = module.key_vault.vault_uri
}

output "key_vault_secrets" {
  description = "Map of secret names to Key Vault Secret IDs."
  value       = module.key_vault.secrets
}

output "key_vault_keys" {
  description = "Map of customer-managed keys generated in Key Vault."
  value       = module.key_vault.keys
}

output "virtual_machines" {
  description = "Map of provisioned virtual machine instances."
  value       = module.compute.virtual_machines
}

output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace."
  value       = module.monitoring.workspace_id
}

output "ssh_public_key" {
  description = "The generated public SSH key for VM administration."
  value       = tls_private_key.ssh_key.public_key_openssh
}

output "ssh_private_key_pem" {
  description = "The generated private SSH key (also backed up securely in Key Vault)."
  value       = tls_private_key.ssh_key.private_key_pem
  sensitive   = true
}

