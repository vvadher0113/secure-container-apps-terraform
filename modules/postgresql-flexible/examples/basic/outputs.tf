output "server_id" {
  description = "Resource ID of the PostgreSQL Flexible Server."
  value       = module.postgresql.id
}

output "fqdn" {
  description = "Fully qualified domain name of the server."
  value       = module.postgresql.fqdn
}

output "database_names" {
  description = "Names of all databases created on the server."
  value       = module.postgresql.database_names
}
