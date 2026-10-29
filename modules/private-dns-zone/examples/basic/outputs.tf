output "zone_id" {
  description = "Resource ID of the private DNS zone."
  value       = module.private_dns_zone.zone_id
}

output "zone_name" {
  description = "Name of the private DNS zone."
  value       = module.private_dns_zone.zone_name
}

output "vnet_link_ids" {
  description = "Map of VNet link name to resource ID."
  value       = module.private_dns_zone.vnet_link_ids
}
