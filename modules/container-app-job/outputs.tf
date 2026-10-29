output "id" {
  description = "Resource ID of the container app job."
  value       = azurerm_container_app_job.this.id
}

output "name" {
  description = "Name of the container app job."
  value       = azurerm_container_app_job.this.name
}
