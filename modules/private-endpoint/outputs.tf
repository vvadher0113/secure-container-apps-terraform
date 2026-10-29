output "id" {
  description = "Resource ID of the private endpoint."
  value       = azurerm_private_endpoint.this.id
}

output "private_ip_address" {
  description = "Private IP address assigned to the endpoint. Available after apply."
  value       = azurerm_private_endpoint.this.private_service_connection[0].private_ip_address
}

output "network_interface_id" {
  description = "Resource ID of the network interface attached to the private endpoint. Available after apply."
  value       = azurerm_private_endpoint.this.network_interface[0].id
}

output "subresource_names" {
  description = "Subresource names configured on the private service connection."
  value       = azurerm_private_endpoint.this.private_service_connection[0].subresource_names
}
