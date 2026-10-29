output "key_vault_id" {
  description = "Resource ID of the Key Vault."
  value       = module.key_vault.id
}

output "vault_uri" {
  description = "URI of the Key Vault."
  value       = module.key_vault.vault_uri
}

output "private_endpoint_ip" {
  description = "Private IP address of the Key Vault endpoint."
  value       = module.key_vault.private_endpoint_ip
}
