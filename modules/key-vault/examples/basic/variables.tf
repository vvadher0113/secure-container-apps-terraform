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

variable "tenant_id" {
  type        = string
  description = "Azure Active Directory tenant ID."

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.tenant_id))
    error_message = "tenant_id must be a valid lowercase UUID."
  }
}

variable "subnet_id" {
  type        = string
  description = "Resource ID of the private endpoint subnet (snet-pe)."
}

variable "private_dns_zone_id" {
  type        = string
  description = "Resource ID of the privatelink.vaultcore.azure.net private DNS zone."
}

variable "soft_delete_retention_days" {
  type        = number
  description = "Days to retain deleted vault objects (7-90). Use 7 for non-production environments."
  default     = 90
}
