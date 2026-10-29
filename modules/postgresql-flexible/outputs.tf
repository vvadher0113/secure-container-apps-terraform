output "id" {
  description = "Resource ID of the PostgreSQL Flexible Server."
  value       = azurerm_postgresql_flexible_server.this.id
}

output "name" {
  description = "Name of the PostgreSQL Flexible Server."
  value       = azurerm_postgresql_flexible_server.this.name
}

output "fqdn" {
  description = "Fully qualified domain name of the server. Available after apply."
  value       = azurerm_postgresql_flexible_server.this.fqdn
}

output "database_names" {
  description = "Names of all databases created on the server."
  value       = [for db in azurerm_postgresql_flexible_server_database.this : db.name]
}

output "public_network_access_enabled" {
  description = "Whether public network access is enabled on the server. Always false when this module is used correctly."
  value       = azurerm_postgresql_flexible_server.this.public_network_access_enabled
}

output "password_auth_enabled" {
  description = "Whether password authentication is enabled. Always false; the server uses Entra-only authentication."
  value       = azurerm_postgresql_flexible_server.this.authentication[0].password_auth_enabled
}
