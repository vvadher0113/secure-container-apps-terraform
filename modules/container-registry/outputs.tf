output "id" {
  description = "Resource ID of the container registry."
  value       = azurerm_container_registry.this.id
}

output "name" {
  description = "Name of the container registry."
  value       = azurerm_container_registry.this.name
}

output "login_server" {
  description = "Login server hostname used to push and pull images (e.g. acrgoalsdev.azurecr.io)."
  value       = azurerm_container_registry.this.login_server
}

output "network_rule_default_action" {
  description = "Default network rule action on the registry. Always Deny; the registry is accessible only via its private endpoint."
  value       = azurerm_container_registry.this.network_rule_set[0].default_action
}
