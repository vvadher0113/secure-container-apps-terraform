mock_provider "azurerm" {}

variables {
  name                         = "job-migrate"
  resource_group_name          = "rg-test"
  location                     = "eastus2"
  container_app_environment_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.App/managedEnvironments/cae-goals-dev"
  user_assigned_identity_id    = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-migrate"
  acr_login_server             = "acrgoalsdev.azurecr.io"
  image                        = "acrgoalsdev.azurecr.io/migrate:abc1234"
  cpu                          = 0.25
  memory                       = "0.5Gi"
}

# The job must use a manual trigger only; no schedule or event trigger is set.
run "manual_trigger_only" {
  command = plan

  assert {
    condition     = length(azurerm_container_app_job.this.manual_trigger_config) == 1
    error_message = "manual_trigger_config must be set."
  }

  assert {
    condition     = azurerm_container_app_job.this.manual_trigger_config[0].parallelism == 1
    error_message = "manual_trigger_config.parallelism must be 1."
  }

  assert {
    condition     = length(azurerm_container_app_job.this.event_trigger_config) == 0
    error_message = "event_trigger_config must not be set."
  }

  assert {
    condition     = length(azurerm_container_app_job.this.schedule_trigger_config) == 0
    error_message = "schedule_trigger_config must not be set."
  }
}

# The identity must be UserAssigned; system-assigned identity cannot pull from ACR by name.
run "identity_is_user_assigned" {
  command = plan

  assert {
    condition     = azurerm_container_app_job.this.identity[0].type == "UserAssigned"
    error_message = "identity.type must be UserAssigned."
  }
}

# The registry block must use the managed identity so no credentials are stored anywhere.
run "registry_uses_identity" {
  command = plan

  assert {
    condition     = azurerm_container_app_job.this.registry[0].identity == var.user_assigned_identity_id
    error_message = "registry.identity must be set to the user-assigned identity; no username/password permitted."
  }
}

# Replica timeout must default to 600 seconds.
run "timeout_default" {
  command = plan

  assert {
    condition     = azurerm_container_app_job.this.replica_timeout_in_seconds == 600
    error_message = "replica_timeout_in_seconds must default to 600."
  }
}

# Replica retry limit must default to 1.
run "retry_limit_default" {
  command = plan

  assert {
    condition     = azurerm_container_app_job.this.replica_retry_limit == 1
    error_message = "replica_retry_limit must default to 1."
  }
}

run "rejects_replica_timeout_too_short" {
  command = plan

  expect_failures = [var.replica_timeout_in_seconds]

  variables {
    replica_timeout_in_seconds = 30
  }
}

run "rejects_retry_limit_too_high" {
  command = plan

  expect_failures = [var.replica_retry_limit]

  variables {
    replica_retry_limit = 10
  }
}

run "rejects_secret_with_plain_value" {
  command = plan

  expect_failures = [var.secrets]

  variables {
    secrets = [
      {
        name  = "migration-token"
        value = "supersecret"
      }
    ]
  }
}
