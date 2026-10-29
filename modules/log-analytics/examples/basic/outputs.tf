output "workspace_id" {
  description = "Workspace GUID used in diagnostic settings and Log Analytics queries."
  value       = module.log_analytics.workspace_id
}

output "id" {
  description = "Resource ID of the Log Analytics workspace."
  value       = module.log_analytics.id
}
