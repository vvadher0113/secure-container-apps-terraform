output "id" {
  description = "Resource ID of the Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.this.id
}

output "name" {
  description = "Name of the Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.this.name
}

output "workspace_id" {
  description = "Unique workspace ID (GUID) used when querying Log Analytics and configuring data sources."
  value       = azurerm_log_analytics_workspace.this.workspace_id
}
