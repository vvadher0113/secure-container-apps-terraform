mock_provider "azurerm" {}

variables {
  name                = "kv-test-goals"
  resource_group_name = "rg-test"
  location            = "eastus2"
  tenant_id           = "00000000-0000-0000-0000-000000000000"
  subnet_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-pe"
  private_dns_zone_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
}

# RBAC authorization is the only supported authorization model; access policy mode is not permitted.
run "rbac_authorization_enabled" {
  command = plan

  assert {
    condition     = azurerm_key_vault.this.rbac_authorization_enabled == true
    error_message = "rbac_authorization_enabled must be true."
  }
}

# Purge protection prevents immediate permanent deletion of the vault and its objects.
run "purge_protection_enabled_by_default" {
  command = plan

  assert {
    condition     = azurerm_key_vault.this.purge_protection_enabled == true
    error_message = "purge_protection_enabled must default to true."
  }
}

# Public network access must be off; the vault is reachable only through its private endpoint.
run "public_network_access_disabled_by_default" {
  command = plan

  assert {
    condition     = azurerm_key_vault.this.public_network_access_enabled == false
    error_message = "public_network_access_enabled must default to false."
  }
}

# The network ACL default action must deny all traffic not routed through the private endpoint.
run "network_acl_default_action_deny" {
  command = plan

  assert {
    condition     = azurerm_key_vault.this.network_acls[0].default_action == "Deny"
    error_message = "network_acls.default_action must be Deny."
  }
}

# The private endpoint must target the vault subresource so DNS resolves to the private IP.
run "private_endpoint_uses_vault_subresource" {
  command = plan

  assert {
    condition     = module.private_endpoint.subresource_names[0] == "vault"
    error_message = "Private endpoint must use the vault subresource."
  }
}

run "rejects_soft_delete_below_minimum" {
  command = plan

  expect_failures = [var.soft_delete_retention_days]

  variables {
    soft_delete_retention_days = 5
  }
}

run "rejects_invalid_sku" {
  command = plan

  expect_failures = [var.sku_name]

  variables {
    sku_name = "free"
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
