mock_provider "azurerm" {}

variables {
  name                         = "app-web"
  resource_group_name          = "rg-test"
  container_app_environment_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.App/managedEnvironments/cae-goals-dev"
  user_assigned_identity_id    = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-web"
  acr_login_server             = "acrgoalsdev.azurecr.io"
  image                        = "acrgoalsdev.azurecr.io/web:abc1234"
  target_port                  = 80
  cpu                          = 0.25
  memory                       = "0.5Gi"
}

# The identity must be UserAssigned; system-assigned identity cannot pull from ACR by name.
run "identity_is_user_assigned" {
  command = plan

  assert {
    condition     = azurerm_container_app.this.identity[0].type == "UserAssigned"
    error_message = "identity.type must be UserAssigned."
  }
}

# The registry block must use the managed identity so no credentials are stored anywhere.
run "registry_uses_identity" {
  command = plan

  assert {
    condition     = azurerm_container_app.this.registry[0].identity == var.user_assigned_identity_id
    error_message = "registry.identity must be set to the user-assigned identity; no username/password permitted."
  }
}

# Insecure HTTP ingress must be disabled; traffic from App Gateway arrives over HTTPS.
run "insecure_connections_off" {
  command = plan

  assert {
    condition     = azurerm_container_app.this.ingress[0].allow_insecure_connections == false
    error_message = "ingress.allow_insecure_connections must be false."
  }
}

# A liveness probe must be configured so the platform can restart unhealthy containers.
run "liveness_probe_configured" {
  command = plan

  assert {
    condition     = azurerm_container_app.this.template[0].container[0].liveness_probe[0].port == var.target_port
    error_message = "A liveness probe must be configured on target_port."
  }
}

# A readiness probe must be configured so the platform withholds traffic from unready containers.
run "readiness_probe_configured" {
  command = plan

  assert {
    condition     = azurerm_container_app.this.template[0].container[0].readiness_probe[0].port == var.target_port
    error_message = "A readiness probe must be configured on target_port."
  }
}

run "rejects_invalid_cpu_memory_pair" {
  command = plan

  expect_failures = [azurerm_container_app.this]

  variables {
    cpu    = 0.25
    memory = "1Gi"
  }
}

run "rejects_secret_with_plain_value" {
  command = plan

  expect_failures = [var.secrets]

  variables {
    secrets = [
      {
        name  = "db-password"
        value = "supersecret"
      }
    ]
  }
}

# When health_path is overridden both probes must use the new path.
run "health_path_overridden" {
  command = plan

  variables {
    health_path = "/healthz"
  }

  assert {
    condition     = azurerm_container_app.this.template[0].container[0].liveness_probe[0].path == "/healthz"
    error_message = "liveness_probe.path must equal health_path when overridden."
  }

  assert {
    condition     = azurerm_container_app.this.template[0].container[0].readiness_probe[0].path == "/healthz"
    error_message = "readiness_probe.path must equal health_path when overridden."
  }
}
