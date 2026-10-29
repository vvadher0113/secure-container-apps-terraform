mock_provider "azurerm" {}

variables {
  name                = "acrgoalsdev"
  resource_group_name = "rg-test"
  location            = "eastus2"
  subnet_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-pe"
  private_dns_zone_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/privateDnsZones/privatelink.azurecr.io"
}

# Admin credentials must be disabled; all access is via managed identity (AcrPull/AcrPush roles).
run "admin_enabled_false" {
  command = plan

  assert {
    condition     = azurerm_container_registry.this.admin_enabled == false
    error_message = "admin_enabled must be false."
  }
}

# Anonymous pull must be disabled so unauthenticated clients cannot pull images.
run "anonymous_pull_disabled" {
  command = plan

  assert {
    condition     = azurerm_container_registry.this.anonymous_pull_enabled == false
    error_message = "anonymous_pull_enabled must be false."
  }
}

# The network rule default must deny all traffic so there is no standing public access.
run "network_default_action_deny" {
  command = plan

  assert {
    condition     = azurerm_container_registry.this.network_rule_set[0].default_action == "Deny"
    error_message = "network_rule_set.default_action must be Deny."
  }
}

# Premium SKU is required for private endpoints, network rules, and zone redundancy.
run "sku_is_premium" {
  command = plan

  assert {
    condition     = azurerm_container_registry.this.sku == "Premium"
    error_message = "sku must be Premium."
  }
}

# The private endpoint must target the registry subresource so DNS resolves to the private IP.
run "private_endpoint_uses_registry_subresource" {
  command = plan

  assert {
    condition     = module.private_endpoint.subresource_names[0] == "registry"
    error_message = "Private endpoint must use the registry subresource."
  }
}

run "rejects_retention_below_minimum" {
  command = plan

  expect_failures = [var.retention_days]

  variables {
    retention_days = 0
  }
}

run "rejects_retention_above_maximum" {
  command = plan

  expect_failures = [var.retention_days]

  variables {
    retention_days = 366
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
