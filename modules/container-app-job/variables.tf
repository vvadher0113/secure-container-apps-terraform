variable "name" {
  type        = string
  description = "Container Apps job name (1-32 chars, lowercase letters, numbers, hyphens; must start with a letter)."

  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 32 && can(regex("^[a-z][a-z0-9-]*$", var.name))
    error_message = "name must be 1-32 characters: lowercase letters, numbers, or hyphens; must start with a letter."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group."

  validation {
    condition     = can(regex("^[a-zA-Z0-9._()\\-]{1,90}$", var.resource_group_name))
    error_message = "resource_group_name must be 1-90 characters: letters, numbers, periods, underscores, hyphens, or parentheses."
  }
}

variable "location" {
  type        = string
  description = "Azure region for the job resource."
}

variable "container_app_environment_id" {
  type        = string
  description = "Resource ID of the Container Apps environment."

  validation {
    condition = can(regex(
      "^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.App/managedEnvironments/[^/]+$",
      var.container_app_environment_id
    ))
    error_message = "container_app_environment_id must be a valid Container Apps environment resource ID."
  }
}

variable "workload_profile_name" {
  type        = string
  description = "Workload profile to run the job on. Must exist in the Container Apps environment."
  default     = "Consumption"
}

variable "user_assigned_identity_id" {
  type        = string
  description = "Resource ID of the user-assigned managed identity. Used for the job identity and ACR pull."

  validation {
    condition = can(regex(
      "^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.ManagedIdentity/userAssignedIdentities/[^/]+$",
      var.user_assigned_identity_id
    ))
    error_message = "user_assigned_identity_id must be a valid user-assigned managed identity resource ID."
  }
}

variable "acr_login_server" {
  type        = string
  description = "Login server hostname of the container registry (e.g. acrgoalsdev.azurecr.io)."

  validation {
    condition     = can(regex("^[a-zA-Z0-9]+\\.azurecr\\.io$", var.acr_login_server))
    error_message = "acr_login_server must be a valid ACR login server, e.g. acrgoalsdev.azurecr.io."
  }
}

variable "image" {
  type        = string
  description = "Full container image reference including registry, name, and tag (e.g. acrgoalsdev.azurecr.io/migrate:abc1234)."

  validation {
    condition     = length(trimspace(var.image)) > 0
    error_message = "image must not be empty."
  }
}

variable "cpu" {
  type        = number
  description = "CPU allocation per replica. Must form an allowed pair with memory: 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, or 2.0."

  validation {
    condition     = contains([0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0], var.cpu)
    error_message = "cpu must be one of: 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0."
  }
}

variable "memory" {
  type        = string
  description = "Memory allocation per replica. Must form an allowed pair with cpu: 0.5Gi, 1Gi, 1.5Gi, 2Gi, 2.5Gi, 3Gi, 3.5Gi, or 4Gi."

  validation {
    condition     = contains(["0.5Gi", "1Gi", "1.5Gi", "2Gi", "2.5Gi", "3Gi", "3.5Gi", "4Gi"], var.memory)
    error_message = "memory must be one of: 0.5Gi, 1Gi, 1.5Gi, 2Gi, 2.5Gi, 3Gi, 3.5Gi, 4Gi."
  }
}

variable "env_vars" {
  type = list(object({
    name        = string
    value       = optional(string)
    secret_name = optional(string)
  }))
  description = "Environment variables for the container. Use secret_name to reference a secret by name instead of embedding a value."
  default     = []
}

variable "command" {
  type        = list(string)
  description = "Optional override for the container entrypoint. Null uses the image's default CMD/ENTRYPOINT."
  default     = null
}

variable "args" {
  type        = list(string)
  description = "Optional arguments passed to the container command."
  default     = null
}

variable "replica_timeout_in_seconds" {
  type        = number
  description = "Maximum duration for a replica to run before the platform terminates it. Must be 60-3600."
  default     = 600

  validation {
    condition     = var.replica_timeout_in_seconds >= 60 && var.replica_timeout_in_seconds <= 3600
    error_message = "replica_timeout_in_seconds must be between 60 and 3600."
  }
}

variable "replica_retry_limit" {
  type        = number
  description = "Maximum number of times the platform retries a failed replica. Must be 0-5."
  default     = 1

  validation {
    condition     = var.replica_retry_limit >= 0 && var.replica_retry_limit <= 5
    error_message = "replica_retry_limit must be between 0 and 5."
  }
}

variable "secrets" {
  type = list(object({
    name                = string
    key_vault_secret_id = optional(string)
    identity            = optional(string)
    value               = optional(string)
  }))
  description = "Key Vault secret references for the job. value must be null; plain text secrets are not permitted."
  default     = []

  validation {
    condition = alltrue([
      for s in var.secrets : s.value == null
    ])
    error_message = "Secrets must use Key Vault references (key_vault_secret_id + identity). Plain text values are not permitted."
  }

  validation {
    condition = alltrue([
      for s in var.secrets : s.key_vault_secret_id != null && s.key_vault_secret_id != ""
    ])
    error_message = "Each secret must have a non-empty key_vault_secret_id."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the job resource."
  default     = {}
}
