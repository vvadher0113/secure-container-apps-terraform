mock_provider "azurerm" {}

variables {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = "rg-test"
  vnet_links = [
    {
      name               = "link-main"
      virtual_network_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test"
    },
  ]
}

# Every zone must have at least one VNet link; without one the zone is unreachable.
run "zone_has_vnet_link" {
  command = plan

  assert {
    condition     = length(azurerm_private_dns_zone_virtual_network_link.this) == 1
    error_message = "Expected one VNet link; got ${length(azurerm_private_dns_zone_virtual_network_link.this)}."
  }
}

# Automatic DNS registration is off by default to prevent VM records polluting the zone namespace.
run "registration_enabled_defaults_to_false" {
  command = plan

  assert {
    condition     = azurerm_private_dns_zone_virtual_network_link.this["link-main"].registration_enabled == false
    error_message = "registration_enabled must default to false; got ${azurerm_private_dns_zone_virtual_network_link.this["link-main"].registration_enabled}."
  }
}

# Multiple links all inherit registration_enabled = false unless explicitly set.
run "multiple_links_all_default_registration_false" {
  command = plan

  variables {
    vnet_links = [
      {
        name               = "link-main"
        virtual_network_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test"
      },
      {
        name               = "link-secondary"
        virtual_network_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-secondary"
      },
    ]
  }

  assert {
    condition     = length(azurerm_private_dns_zone_virtual_network_link.this) == 2
    error_message = "Expected 2 VNet links; got ${length(azurerm_private_dns_zone_virtual_network_link.this)}."
  }

  assert {
    condition = alltrue([
      for link in azurerm_private_dns_zone_virtual_network_link.this : link.registration_enabled == false
    ])
    error_message = "All VNet links must default to registration_enabled = false."
  }
}

# The container-apps-environment module passes the environment's default_domain as the zone
# name. Confirm the validation accepts that pattern: subdomain.random.region.azurecontainerapps.io.
run "accepts_container_apps_default_domain" {
  command = plan

  variables {
    name = "cae-goals-dev.bravestone-12345.eastus2.azurecontainerapps.io"
  }

  assert {
    condition     = azurerm_private_dns_zone.this.name == "cae-goals-dev.bravestone-12345.eastus2.azurecontainerapps.io"
    error_message = "Validation must accept a Container Apps default domain as a zone name."
  }
}

run "rejects_no_vnet_links" {
  command = plan

  expect_failures = [var.vnet_links]

  variables {
    vnet_links = []
  }
}

run "rejects_invalid_vnet_resource_id" {
  command = plan

  expect_failures = [var.vnet_links]

  variables {
    vnet_links = [
      {
        name               = "link-bad"
        virtual_network_id = "not-a-resource-id"
      },
    ]
  }
}
