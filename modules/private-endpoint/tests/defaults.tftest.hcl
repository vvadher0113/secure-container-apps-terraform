mock_provider "azurerm" {}

variables {
  name                = "pe-kv-test"
  location            = "eastus2"
  resource_group_name = "rg-test"
  subnet_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-pe"
  target_resource_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.KeyVault/vaults/kv-test"
  subresource_names   = ["vault"]
  private_dns_zone_ids = [
    "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net",
  ]
}

# Without a DNS zone group the endpoint gets a private IP but DNS keeps resolving to the public IP,
# so private resolution never works. The group must always be created.
run "dns_zone_group_always_present" {
  command = plan

  assert {
    condition     = length(azurerm_private_endpoint.this.private_dns_zone_group) == 1
    error_message = "private_dns_zone_group must always be created; got ${length(azurerm_private_endpoint.this.private_dns_zone_group)}."
  }
}

# Manual approval requires a human to approve the connection before the endpoint is usable.
# Always use automatic approval (is_manual_connection = false).
run "is_manual_connection_always_false" {
  command = plan

  assert {
    condition     = azurerm_private_endpoint.this.private_service_connection[0].is_manual_connection == false
    error_message = "is_manual_connection must always be false."
  }
}

run "rejects_empty_private_dns_zone_ids" {
  command = plan

  expect_failures = [var.private_dns_zone_ids]

  variables {
    private_dns_zone_ids = []
  }
}

run "rejects_unknown_subresource_name" {
  command = plan

  expect_failures = [var.subresource_names]

  variables {
    subresource_names = ["unknownSubresource"]
  }
}

run "rejects_multiple_subresource_names" {
  command = plan

  expect_failures = [var.subresource_names]

  variables {
    subresource_names = ["vault", "registry"]
  }
}
