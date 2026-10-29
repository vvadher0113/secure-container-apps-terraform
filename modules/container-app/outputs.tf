output "id" {
  description = "Resource ID of the container app."
  value       = azurerm_container_app.this.id
}

output "name" {
  description = "Name of the container app."
  value       = azurerm_container_app.this.name
}

output "fqdn" {
  description = "FQDN of the latest revision. Available after apply; used as App Gateway backend address."
  value       = azurerm_container_app.this.latest_revision_fqdn
}

output "latest_revision_name" {
  description = "Name of the latest active revision. Available after apply."
  value       = azurerm_container_app.this.latest_revision_name
}
