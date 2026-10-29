variable "subscription_id" {
  type        = string
  description = "Azure subscription ID."

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.subscription_id))
    error_message = "subscription_id must be a valid lowercase UUID."
  }
}

variable "container_app_environment_id" {
  type        = string
  description = "Resource ID of the Container Apps environment."
}

variable "user_assigned_identity_id" {
  type        = string
  description = "Resource ID of the user-assigned managed identity (e.g. id-web)."
}

variable "acr_login_server" {
  type        = string
  description = "Login server hostname of the container registry."
}

variable "image" {
  type        = string
  description = "Full container image reference."
}
