variable "subscription_id" {
  type        = string
  description = "Azure subscription ID."

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.subscription_id))
    error_message = "subscription_id must be a valid lowercase UUID."
  }
}

variable "subnet_id" {
  type        = string
  description = "Resource ID of the App Gateway subnet."
}

variable "user_assigned_identity_id" {
  type        = string
  description = "Resource ID of the user-assigned managed identity for App Gateway (e.g. id-agw)."
}

variable "web_fqdn" {
  type        = string
  description = "FQDN of the web Container App."
}

variable "api_fqdn" {
  type        = string
  description = "FQDN of the API Container App."
}
