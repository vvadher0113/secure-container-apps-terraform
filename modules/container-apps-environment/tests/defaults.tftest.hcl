mock_provider "azurerm" {}

variables {
  name                     = "cae-goals-dev"
  resource_group_name      = "rg-test"
  location                 = "eastus2"
  infrastructure_subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-aca"
  vnet_links = [
    {
      name               = "link-vnet-test"
      virtual_network_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test"
    }
  ]
  log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/law-goals-dev"
}

# Internal load balancer must be on; the environment must not be reachable from the internet.
run "internal_load_balancer_on" {
  command = plan

  assert {
    condition     = azurerm_container_app_environment.this.internal_load_balancer_enabled == true
    error_message = "internal_load_balancer_enabled must be true."
  }
}

# logs_destination must be azure-monitor, not log-analytics, because the Log Analytics
# workspace has local_authentication_enabled = false which disables the workspace key path.
run "logs_destination_azure_monitor" {
  command = plan

  assert {
    condition     = azurerm_container_app_environment.this.logs_destination == "azure-monitor"
    error_message = "logs_destination must be azure-monitor."
  }
}

# A diagnostic setting must exist when diagnostics_enabled is true and a workspace ID is supplied.
run "diagnostic_setting_created" {
  command = plan

  variables {
    diagnostics_enabled = true
  }

  assert {
    condition     = length(azurerm_monitor_diagnostic_setting.this) == 1
    error_message = "A diagnostic setting must be created when diagnostics_enabled is true."
  }
}

# A wildcard A record must exist so all app FQDNs resolve to the environment's static IP.
run "wildcard_a_record_created" {
  command = plan

  assert {
    condition     = azurerm_private_dns_a_record.wildcard.name == "*"
    error_message = "A wildcard (*) DNS A record must be created."
  }
}

# An apex A record must exist so the bare domain itself resolves.
run "apex_a_record_created" {
  command = plan

  assert {
    condition     = azurerm_private_dns_a_record.apex.name == "@"
    error_message = "An apex (@) DNS A record must be created."
  }
}

run "rejects_diagnostics_without_workspace_id" {
  command = plan

  expect_failures = [azurerm_monitor_diagnostic_setting.this[0]]

  variables {
    diagnostics_enabled        = true
    log_analytics_workspace_id = ""
  }
}
