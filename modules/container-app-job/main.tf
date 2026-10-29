# tflint-ignore: azurerm_resources_missing_prevent_destroy -- the job runs idempotent migrations; state lives in PostgreSQL which has its own backup retention
resource "azurerm_container_app_job" "this" {
  name                         = var.name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  container_app_environment_id = var.container_app_environment_id
  workload_profile_name        = var.workload_profile_name
  replica_timeout_in_seconds   = var.replica_timeout_in_seconds
  replica_retry_limit          = var.replica_retry_limit
  tags                         = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [var.user_assigned_identity_id]
  }

  registry {
    server   = var.acr_login_server
    identity = var.user_assigned_identity_id
  }

  manual_trigger_config {
    parallelism              = 1
    replica_completion_count = 1
  }

  dynamic "secret" {
    for_each = { for s in var.secrets : s.name => s }
    content {
      name                = secret.value.name
      key_vault_secret_id = secret.value.key_vault_secret_id
      identity            = secret.value.identity
    }
  }

  template {
    container {
      name    = var.name
      image   = var.image
      cpu     = var.cpu
      memory  = var.memory
      command = var.command
      args    = var.args

      dynamic "env" {
        for_each = var.env_vars
        content {
          name        = env.value.name
          value       = env.value.value
          secret_name = env.value.secret_name
        }
      }
    }
  }

  lifecycle {
    precondition {
      condition = contains([
        { cpu = 0.25, memory = "0.5Gi" },
        { cpu = 0.5, memory = "1Gi" },
        { cpu = 0.75, memory = "1.5Gi" },
        { cpu = 1.0, memory = "2Gi" },
        { cpu = 1.25, memory = "2.5Gi" },
        { cpu = 1.5, memory = "3Gi" },
        { cpu = 1.75, memory = "3.5Gi" },
        { cpu = 2.0, memory = "4Gi" },
      ], { cpu = var.cpu, memory = var.memory })
      error_message = "cpu and memory must form a valid pair: 0.25/0.5Gi, 0.5/1Gi, 0.75/1.5Gi, 1.0/2Gi, 1.25/2.5Gi, 1.5/3Gi, 1.75/3.5Gi, 2.0/4Gi."
    }
  }
}
