output "id" {
  description = "Resource ID of the Application Gateway."
  value       = azurerm_application_gateway.this.id
}

output "public_ip_address" {
  description = "Public IP address of the Application Gateway. Available after apply."
  value       = azurerm_public_ip.this.ip_address
}

output "waf_policy_id" {
  description = "Resource ID of the WAF policy."
  value       = azurerm_web_application_firewall_policy.this.id
}

output "waf_mode" {
  description = "Operational mode of the WAF policy. Should always be Prevention in production."
  value       = azurerm_web_application_firewall_policy.this.policy_settings[0].mode
}
