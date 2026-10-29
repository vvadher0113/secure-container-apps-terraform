output "id" {
  description = "Resource ID of the Key Vault."
  value       = azurerm_key_vault.this.id
}

output "name" {
  description = "Name of the Key Vault."
  value       = azurerm_key_vault.this.name
}

output "vault_uri" {
  description = "URI of the Key Vault, e.g. https://kv-goals-dev.vault.azure.net/."
  value       = azurerm_key_vault.this.vault_uri
}

output "private_endpoint_ip" {
  description = "Private IP address of the Key Vault private endpoint. Available after apply."
  value       = module.private_endpoint.private_ip_address
}

output "public_network_access_enabled" {
  description = "Whether public network access is enabled. Always false; the vault is accessible only via its private endpoint."
  value       = azurerm_key_vault.this.public_network_access_enabled
}
