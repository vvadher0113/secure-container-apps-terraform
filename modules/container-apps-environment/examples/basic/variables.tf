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

variable "infrastructure_subnet_id" {
  type        = string
  description = "Resource ID of the subnet delegated to Microsoft.App/environments (snet-aca)."
}

variable "vnet_id" {
  type        = string
  description = "Resource ID of the VNet to link to the environment's private DNS zone."
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Resource ID of the Log Analytics workspace for diagnostic settings."
}
