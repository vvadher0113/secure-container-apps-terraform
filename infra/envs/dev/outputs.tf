output "resource_group_name" {
  description = "Name of the workload resource group."
  value       = azurerm_resource_group.main.name
}

output "acr_login_server" {
  description = "Login server hostname of the container registry. Use this as the image prefix in build-push."
  value       = module.container_registry.login_server
}

output "migrate_job_name" {
  description = "Name of the migration Container App Job. Start it with: az containerapp job start --name <value> --resource-group <resource_group_name>"
  value       = module.migrate.name
}

output "app_gateway_public_ip" {
  description = "Public IP address of the Application Gateway. Available after apply."
  value       = module.app_gateway.public_ip_address
}

output "app_url" {
  description = "Base URL to reach the application through App Gateway. Uses HTTP unless tls_certificate_key_vault_secret_id is set."
  value       = var.tls_certificate_key_vault_secret_id != "" ? "https://${module.app_gateway.public_ip_address}" : "http://${module.app_gateway.public_ip_address}"
}
