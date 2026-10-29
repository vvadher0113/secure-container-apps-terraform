output "app_id" {
  description = "Resource ID of the container app."
  value       = module.web_app.id
}

output "fqdn" {
  description = "FQDN of the latest revision."
  value       = module.web_app.fqdn
}
