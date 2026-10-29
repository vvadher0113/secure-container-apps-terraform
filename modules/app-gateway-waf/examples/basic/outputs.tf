output "gateway_id" {
  description = "Resource ID of the Application Gateway."
  value       = module.app_gateway.id
}

output "public_ip_address" {
  description = "Public IP address of the Application Gateway."
  value       = module.app_gateway.public_ip_address
}

output "waf_policy_id" {
  description = "Resource ID of the WAF policy."
  value       = module.app_gateway.waf_policy_id
}
