output "registry_id" {
  description = "Resource ID of the container registry."
  value       = module.container_registry.id
}

output "login_server" {
  description = "Login server hostname for the container registry."
  value       = module.container_registry.login_server
}
