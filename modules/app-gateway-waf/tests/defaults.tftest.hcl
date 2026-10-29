mock_provider "azurerm" {}

variables {
  name                      = "agw-goals-dev"
  resource_group_name       = "rg-test"
  location                  = "eastus2"
  subnet_id                 = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-goals-dev/subnets/snet-agw"
  user_assigned_identity_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-agw"
  autoscale_min_capacity    = 1
  autoscale_max_capacity    = 5
  backends = {
    web = "app-web.cae-goals-dev.bravestone-12345.eastus2.azurecontainerapps.io"
    api = "app-api.cae-goals-dev.bravestone-12345.eastus2.azurecontainerapps.io"
  }
}

# SKU must be WAF_v2; Standard_v2 lacks WAF capabilities.
run "sku_waf_v2" {
  command = plan

  assert {
    condition     = azurerm_application_gateway.this.sku[0].name == "WAF_v2"
    error_message = "sku.name must be WAF_v2."
  }

  assert {
    condition     = azurerm_application_gateway.this.sku[0].tier == "WAF_v2"
    error_message = "sku.tier must be WAF_v2."
  }
}

# WAF must default to Prevention mode so attacks are blocked, not just logged.
run "waf_mode_prevention" {
  command = plan

  assert {
    condition     = azurerm_web_application_firewall_policy.this.policy_settings[0].mode == "Prevention"
    error_message = "WAF policy mode must default to Prevention."
  }

  assert {
    condition     = azurerm_web_application_firewall_policy.this.policy_settings[0].enabled == true
    error_message = "WAF policy must be enabled."
  }
}

# TLS 1.2 minimum enforced via the predefined AppGwSslPolicy20220101S policy.
run "ssl_policy_predefined" {
  command = plan

  assert {
    condition     = azurerm_application_gateway.this.ssl_policy[0].policy_name == "AppGwSslPolicy20220101S"
    error_message = "ssl_policy.policy_name must be AppGwSslPolicy20220101S."
  }

  assert {
    condition     = azurerm_application_gateway.this.ssl_policy[0].policy_type == "Predefined"
    error_message = "ssl_policy.policy_type must be Predefined."
  }
}

# All backend settings must use HTTPS and pick host from backend so the SNI name
# matches the Container Apps FQDN that the private DNS zone resolves.
run "backend_settings_https_with_host_header" {
  command = plan

  assert {
    condition = alltrue([
      for s in azurerm_application_gateway.this.backend_http_settings :
      s.protocol == "Https" && s.pick_host_name_from_backend_address == true
    ])
    error_message = "All backend_http_settings must use HTTPS and pick_host_name_from_backend_address."
  }
}

# The /api/* path rule must route to the api backend pool.
run "path_rule_api_present" {
  command = plan

  assert {
    condition = length([
      for pr in azurerm_application_gateway.this.url_path_map[0].path_rule :
      pr if contains(pr.paths, "/api/*")
    ]) == 1
    error_message = "url_path_map must contain a path_rule with path /api/*."
  }
}

# Without a TLS certificate only the HTTP listener must be present (no HTTPS listener).
run "http_only_listener_when_no_cert" {
  command = plan

  assert {
    condition = length([
      for l in azurerm_application_gateway.this.http_listener :
      l if l.protocol == "Https"
    ]) == 0
    error_message = "No HTTPS listener should exist when tls_certificate_key_vault_secret_id is empty."
  }

  assert {
    condition = length([
      for l in azurerm_application_gateway.this.http_listener :
      l if l.protocol == "Http"
    ]) == 1
    error_message = "Exactly one HTTP listener must exist when no TLS certificate is configured."
  }
}

# When a TLS certificate is provided the HTTPS listener must be present and HTTP
# must have a redirect configuration to HTTPS.
run "https_listener_and_redirect_when_cert_provided" {
  command = plan

  variables {
    tls_certificate_key_vault_secret_id = "https://kv-goals-dev.vault.azure.net/secrets/agw-tls-cert"
  }

  assert {
    condition = length([
      for l in azurerm_application_gateway.this.http_listener :
      l if l.protocol == "Https"
    ]) == 1
    error_message = "Exactly one HTTPS listener must exist when a TLS certificate is configured."
  }

  assert {
    condition     = length(azurerm_application_gateway.this.redirect_configuration) == 1
    error_message = "A redirect configuration from HTTP to HTTPS must exist when a TLS certificate is configured."
  }
}

run "rejects_waf_mode_off" {
  command = plan

  expect_failures = [var.waf_mode]

  variables {
    waf_mode = "Off"
  }
}

run "rejects_autoscale_min_greater_than_max" {
  command = plan

  expect_failures = [azurerm_application_gateway.this]

  variables {
    autoscale_min_capacity = 10
    autoscale_max_capacity = 2
  }
}

run "rejects_diagnostics_without_workspace_id" {
  command = plan

  expect_failures = [azurerm_monitor_diagnostic_setting.this[0]]

  variables {
    diagnostics_enabled = true
    # log_analytics_workspace_id defaults to "" which triggers the precondition
  }
}
