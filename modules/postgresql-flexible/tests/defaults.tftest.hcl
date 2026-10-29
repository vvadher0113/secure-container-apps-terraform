mock_provider "azurerm" {}

variables {
  name                = "psql-goals-dev"
  resource_group_name = "rg-test"
  location            = "eastus2"
  tenant_id           = "00000000-0000-0000-0000-000000000000"
  entra_admin = {
    object_id      = "00000000-0000-0000-0000-000000000001"
    principal_name = "id-migrate"
    principal_type = "ServicePrincipal"
  }
  databases = [
    { name = "goals" }
  ]
  subnet_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-pe"
  private_dns_zone_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/privateDnsZones/privatelink.postgres.database.azure.com"
}

# Password authentication must be off; the only credential path is an Entra access token.
run "password_auth_disabled" {
  command = plan

  assert {
    condition     = azurerm_postgresql_flexible_server.this.authentication[0].password_auth_enabled == false
    error_message = "password_auth_enabled must be false."
  }
}

# Entra authentication must be on so managed identities can connect with an access token.
run "active_directory_auth_enabled" {
  command = plan

  assert {
    condition     = azurerm_postgresql_flexible_server.this.authentication[0].active_directory_auth_enabled == true
    error_message = "active_directory_auth_enabled must be true."
  }
}

# Public network access must be off; the server is reachable only through its private endpoint.
run "public_access_off" {
  command = plan

  assert {
    condition     = azurerm_postgresql_flexible_server.this.public_network_access_enabled == false
    error_message = "public_network_access_enabled must be false."
  }
}

# The private endpoint must target postgresqlServer so DNS resolves to the private IP.
run "private_endpoint_uses_postgresql_subresource" {
  command = plan

  assert {
    condition     = module.private_endpoint.subresource_names[0] == "postgresqlServer"
    error_message = "Private endpoint must use the postgresqlServer subresource."
  }
}

# The Entra administrator resource must be created with the correct principal_type.
run "entra_admin_created" {
  command = plan

  assert {
    condition     = azurerm_postgresql_flexible_server_active_directory_administrator.this.principal_type == var.entra_admin.principal_type
    error_message = "Entra administrator must be created with the specified principal_type."
  }
}

# TLS 1.2 must be the minimum accepted protocol version.
run "tls_min_version_set" {
  command = plan

  assert {
    condition     = azurerm_postgresql_flexible_server_configuration.ssl_min_protocol_version.value == "TLSv1.2"
    error_message = "ssl_min_protocol_version must be TLSv1.2."
  }
}

run "rejects_backup_retention_too_short" {
  command = plan

  expect_failures = [var.backup_retention_days]

  variables {
    backup_retention_days = 3
  }
}

run "rejects_invalid_principal_type" {
  command = plan

  expect_failures = [var.entra_admin]

  variables {
    entra_admin = {
      object_id      = "00000000-0000-0000-0000-000000000001"
      principal_name = "id-migrate"
      principal_type = "Robot"
    }
  }
}

run "rejects_ha_with_burstable_sku" {
  command = plan

  expect_failures = [azurerm_postgresql_flexible_server.this]

  variables {
    sku_name = "B_Standard_B2ms"
    high_availability = {
      standby_availability_zone = "2"
    }
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
