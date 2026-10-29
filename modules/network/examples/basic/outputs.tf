output "vnet_id" {
  description = "VNet resource ID."
  value       = module.network.vnet_id
}

output "subnet_ids" {
  description = "Map of subnet name to resource ID."
  value       = module.network.subnet_ids
}

output "nsg_ids" {
  description = "Map of subnet name to NSG resource ID."
  value       = module.network.nsg_ids
}
