variable "subscription_id" {
  type        = string
  description = "Azure subscription ID."

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.subscription_id))
    error_message = "subscription_id must be a valid lowercase UUID."
  }
}

variable "location" {
  type        = string
  description = "Azure region."
  default     = "eastus2"
}

variable "subnet_id" {
  type        = string
  description = "Resource ID of the private endpoint subnet."
}

variable "key_vault_id" {
  type        = string
  description = "Resource ID of the Key Vault to connect to."
}

variable "private_dns_zone_id" {
  type        = string
  description = "Resource ID of the privatelink.vaultcore.azure.net private DNS zone."
}
