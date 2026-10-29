output "id" {
  description = "Resource ID of the Container Apps environment."
  value       = azurerm_container_app_environment.this.id
}

output "name" {
  description = "Name of the Container Apps environment."
  value       = azurerm_container_app_environment.this.name
}

output "default_domain" {
  description = "Default domain assigned to the environment (e.g. <hash>.<region>.azurecontainerapps.io). Used to build app FQDNs and to configure DNS."
  value       = azurerm_container_app_environment.this.default_domain
}

output "static_ip_address" {
  description = "Static IP address of the internal load balancer. Available after apply."
  value       = azurerm_container_app_environment.this.static_ip_address
}

output "internal_load_balancer_enabled" {
  description = "Whether the environment uses an internal load balancer. Always true; the environment is VNet-internal and not reachable from the internet."
  value       = azurerm_container_app_environment.this.internal_load_balancer_enabled
}
