variable "name" {
  type        = string
  description = "Container app name (1-32 chars, lowercase letters, numbers, hyphens; must start with a letter)."

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

variable "user_assigned_identity_id" {
  type        = string
  description = "Resource ID of the user-assigned managed identity. Used for the app identity and ACR pull."

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
  description = "Full container image reference including registry, name, and tag (e.g. acrgoalsdev.azurecr.io/web:abc1234)."

  validation {
    condition     = length(trimspace(var.image)) > 0
    error_message = "image must not be empty."
  }
}

variable "target_port" {
  type        = number
  description = "TCP port the container listens on."

  validation {
    condition     = var.target_port >= 1 && var.target_port <= 65535
    error_message = "target_port must be between 1 and 65535."
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

variable "min_replicas" {
  type        = number
  description = "Minimum replica count. Set to 0 to allow scale-to-zero."
  default     = 0

  validation {
    condition     = var.min_replicas >= 0
    error_message = "min_replicas must be >= 0."
  }
}

variable "max_replicas" {
  type        = number
  description = "Maximum replica count."
  default     = 3

  validation {
    condition     = var.max_replicas >= 1
    error_message = "max_replicas must be >= 1."
  }
}

variable "health_path" {
  type        = string
  description = "HTTP path used for liveness and readiness probes."
  default     = "/health"

  validation {
    condition     = startswith(var.health_path, "/")
    error_message = "health_path must start with /."
  }
}

variable "external_enabled" {
  type        = bool
  description = "Expose ingress externally. In an internal environment (internal_load_balancer_enabled = true) this means reachable from the VNet, not the internet. Set to true so App Gateway can route traffic to the app."
  default     = true
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

variable "secrets" {
  type = list(object({
    name                = string
    key_vault_secret_id = optional(string)
    identity            = optional(string)
    value               = optional(string)
  }))
  description = "Key Vault secret references for the app. value must be null; plain text secrets are not permitted."
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

variable "http_scale_concurrent_requests" {
  type        = number
  description = "When set, adds an HTTP scale rule that triggers a new replica when concurrent requests exceed this value. Null disables the rule."
  default     = null

  validation {
    condition     = var.http_scale_concurrent_requests == null || var.http_scale_concurrent_requests >= 1
    error_message = "http_scale_concurrent_requests must be >= 1."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the container app."
  default     = {}
}
