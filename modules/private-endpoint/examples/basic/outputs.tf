output "private_endpoint_id" {
  description = "Resource ID of the private endpoint."
  value       = module.private_endpoint.id
}

output "private_ip_address" {
  description = "Private IP address assigned to the endpoint."
  value       = module.private_endpoint.private_ip_address
}
