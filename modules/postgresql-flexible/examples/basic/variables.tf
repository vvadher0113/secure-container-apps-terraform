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

variable "entra_admin_object_id" {
  type        = string
  description = "Object ID of the identity to set as the PostgreSQL Entra administrator (e.g. the migrate job managed identity)."
}

variable "entra_admin_principal_name" {
  type        = string
  description = "Display name of the Entra admin identity."
}

variable "subnet_id" {
  type        = string
  description = "Resource ID of the private endpoint subnet (snet-pe)."
}

variable "private_dns_zone_id" {
  type        = string
  description = "Resource ID of the privatelink.postgres.database.azure.com private DNS zone."
}
