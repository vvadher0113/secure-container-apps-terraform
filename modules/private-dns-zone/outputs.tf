output "zone_id" {
  description = "Resource ID of the private DNS zone."
  value       = azurerm_private_dns_zone.this.id
}

output "zone_name" {
  description = "Name of the private DNS zone."
  value       = azurerm_private_dns_zone.this.name
}

output "vnet_link_ids" {
  description = "Map of VNet link name to resource ID."
  value       = { for k, v in azurerm_private_dns_zone_virtual_network_link.this : k => v.id }
}
