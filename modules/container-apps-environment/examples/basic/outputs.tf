output "environment_id" {
  description = "Resource ID of the Container Apps environment."
  value       = module.container_apps_environment.id
}

output "default_domain" {
  description = "Default domain of the Container Apps environment."
  value       = module.container_apps_environment.default_domain
}

output "static_ip_address" {
  description = "Static IP address of the environment's internal load balancer."
  value       = module.container_apps_environment.static_ip_address
}
