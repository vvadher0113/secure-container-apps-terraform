mock_provider "azurerm" {}

variables {
  name                = "law-goals-dev"
  resource_group_name = "rg-test"
  location            = "eastus2"
}

# Shared-key authentication allows anyone with the key to ingest and query data.
# Only Entra ID authentication is permitted by default.
run "local_authentication_disabled_by_default" {
  command = plan

  assert {
    condition     = azurerm_log_analytics_workspace.this.local_authentication_enabled == false
    error_message = "local_authentication_enabled must default to false."
  }
}

run "default_sku_is_per_gb_2018" {
  command = plan

  assert {
    condition     = azurerm_log_analytics_workspace.this.sku == "PerGB2018"
    error_message = "Default SKU must be PerGB2018; got ${azurerm_log_analytics_workspace.this.sku}."
  }
}

run "default_retention_is_30_days" {
  command = plan

  assert {
    condition     = azurerm_log_analytics_workspace.this.retention_in_days == 30
    error_message = "Default retention must be 30 days; got ${azurerm_log_analytics_workspace.this.retention_in_days}."
  }
}

run "rejects_retention_below_minimum" {
  command = plan

  expect_failures = [var.retention_in_days]

  variables {
    retention_in_days = 29
  }
}

run "rejects_retention_above_maximum" {
  command = plan

  expect_failures = [var.retention_in_days]

  variables {
    retention_in_days = 731
  }
}

run "rejects_invalid_sku" {
  command = plan

  expect_failures = [var.sku]

  variables {
    sku = "BasicTier"
  }
}
