mock_provider "azurerm" {}
mock_provider "random" {}

variables {
  subscription_id = "00000000-0000-0000-0000-000000000000"
  tenant_id       = "00000000-0000-0000-0000-000000000000"
}

# PostgreSQL must never allow connections from the public internet.
run "postgres_public_access_disabled" {
  command = plan

  assert {
    condition     = module.postgresql.public_network_access_enabled == false
    error_message = "PostgreSQL must have public_network_access_enabled = false."
  }
}

# Password authentication must be disabled so only Entra tokens are accepted.
run "postgres_password_auth_disabled" {
  command = plan

  assert {
    condition     = module.postgresql.password_auth_enabled == false
    error_message = "PostgreSQL password_auth_enabled must be false."
  }
}

# Key Vault must be reachable only via its private endpoint.
run "key_vault_public_access_disabled" {
  command = plan

  assert {
    condition     = module.key_vault.public_network_access_enabled == false
    error_message = "Key Vault must have public_network_access_enabled = false."
  }
}

# ACR network default action must be Deny; only the private endpoint provides access.
# CI adds a temporary IP rule during image push and removes it in an always() step.
run "acr_network_default_deny" {
  command = plan

  assert {
    condition     = module.container_registry.network_rule_default_action == "Deny"
    error_message = "ACR network_rule_set default_action must be Deny."
  }
}

# The Container Apps environment must use an internal load balancer so the apps
# are never directly reachable from the internet.
run "container_apps_env_internal" {
  command = plan

  assert {
    condition     = module.cae.internal_load_balancer_enabled == true
    error_message = "Container Apps environment must have internal_load_balancer_enabled = true."
  }
}

# WAF must be in Prevention mode so detected attacks are blocked, not just logged.
run "waf_mode_prevention" {
  command = plan

  assert {
    condition     = module.app_gateway.waf_mode == "Prevention"
    error_message = "WAF policy mode must be Prevention."
  }
}
