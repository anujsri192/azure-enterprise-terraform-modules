output "id" {
  description = "The ID of the Key Vault."
  value       = azurerm_key_vault.this.id
}

output "name" {
  description = "The name of the Key Vault."
  value       = azurerm_key_vault.this.name
}

output "vault_uri" {
  description = "The URI of the Key Vault for performing operations on keys and secrets."
  value       = azurerm_key_vault.this.vault_uri
}

output "secrets" {
  description = "Map of secret names to their Key Vault Secret resource IDs."
  value       = { for k, v in azurerm_key_vault_secret.this : k => v.id }
}

output "secret_versionless_ids" {
  description = "Map of secret names to their versionless IDs (for automated secret rotation)."
  value       = { for k, v in azurerm_key_vault_secret.this : k => v.versionless_id }
}

output "keys" {
  description = "Map of key names to their Key Vault Key resource IDs."
  value       = { for k, v in azurerm_key_vault_key.this : k => v.id }
}

output "private_endpoint_ip" {
  description = "Private IP of the Key Vault Private Endpoint, if provisioned."
  value = try(
    azurerm_private_endpoint.this[0].private_service_connection[0].private_ip_address,
    null
  )
}

