mock_provider "azurerm" {}

variables {
  name                = "vnet-test"
  resource_group_name = "rg-test"
  location            = "eastus2"
  address_space       = ["10.20.0.0/22"]
  subnets = [
    {
      name           = "snet-agw"
      address_prefix = "10.20.0.0/24"
      nsg_rules = [
        {
          name                       = "allow-gateway-manager"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "65200-65535"
          source_address_prefix      = "GatewayManager"
          destination_address_prefix = "*"
        },
      ]
    },
    {
      name           = "snet-aca"
      address_prefix = "10.20.1.0/24"
      delegation = {
        service = "Microsoft.App/environments"
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    },
    {
      name           = "snet-pe"
      address_prefix = "10.20.2.0/24"
    },
  ]
}

# Every subnet must have its own NSG - there is no opt-out for normal subnet names.
run "every_subnet_gets_an_nsg" {
  command = plan

  assert {
    condition     = length(azurerm_network_security_group.this) == 3
    error_message = "Expected one NSG per subnet; got ${length(azurerm_network_security_group.this)}."
  }
}

# NSGs must be attached - creating them without associations leaves subnets unprotected.
run "all_nsgs_are_associated_with_subnets" {
  command = plan

  assert {
    condition     = length(azurerm_subnet_network_security_group_association.this) == 3
    error_message = "Every subnet must have an NSG association; got ${length(azurerm_subnet_network_security_group_association.this)}."
  }
}

run "delegated_subnet_has_exactly_one_delegation" {
  command = plan

  assert {
    condition     = length(azurerm_subnet.this["snet-aca"].delegation) == 1
    error_message = "snet-aca must have exactly one delegation block."
  }
}

run "non_delegated_subnets_have_no_delegation" {
  command = plan

  assert {
    condition     = length(azurerm_subnet.this["snet-agw"].delegation) == 0
    error_message = "snet-agw must not have a delegation block."
  }

  assert {
    condition     = length(azurerm_subnet.this["snet-pe"].delegation) == 0
    error_message = "snet-pe must not have a delegation block."
  }
}

# Enabled means the subnet NSG applies to private endpoint traffic, which is the secure default.
run "pe_subnet_has_private_endpoint_policies_enabled" {
  command = plan

  assert {
    condition     = azurerm_subnet.this["snet-pe"].private_endpoint_network_policies == "Enabled"
    error_message = "snet-pe must have private_endpoint_network_policies = Enabled so the NSG governs private endpoint traffic."
  }
}

# Azure rejects NSG associations on GatewaySubnet; nsg_enabled = false must be honoured.
run "gateway_subnet_skips_nsg" {
  command = plan

  variables {
    subnets = [
      {
        name           = "GatewaySubnet"
        address_prefix = "10.20.3.0/27"
        nsg_enabled    = false
      },
    ]
  }

  assert {
    condition     = length(azurerm_network_security_group.this) == 0
    error_message = "GatewaySubnet must not produce an NSG resource."
  }

  assert {
    condition     = length(azurerm_subnet_network_security_group_association.this) == 0
    error_message = "GatewaySubnet must not produce an NSG association."
  }
}

run "rejects_nsg_disabled_on_regular_subnet" {
  command = plan

  expect_failures = [var.subnets]

  variables {
    subnets = [
      {
        name           = "snet-pe"
        address_prefix = "10.20.2.0/24"
        nsg_enabled    = false
      },
    ]
  }
}

run "rejects_invalid_address_space_cidr" {
  command = plan

  expect_failures = [var.address_space]

  variables {
    address_space = ["not-a-cidr"]
  }
}

run "rejects_nsg_priority_out_of_range" {
  command = plan

  expect_failures = [var.subnets]

  variables {
    subnets = [
      {
        name           = "snet-test"
        address_prefix = "10.20.0.0/24"
        nsg_rules = [
          {
            name                       = "bad-priority"
            priority                   = 99
            direction                  = "Inbound"
            access                     = "Allow"
            protocol                   = "Tcp"
            source_port_range          = "*"
            destination_port_range     = "443"
            source_address_prefix      = "*"
            destination_address_prefix = "*"
          },
        ]
      },
    ]
  }
}

run "rejects_invalid_nsg_direction" {
  command = plan

  expect_failures = [var.subnets]

  variables {
    subnets = [
      {
        name           = "snet-test"
        address_prefix = "10.20.0.0/24"
        nsg_rules = [
          {
            name                       = "bad-direction"
            priority                   = 100
            direction                  = "Sideways"
            access                     = "Allow"
            protocol                   = "Tcp"
            source_port_range          = "*"
            destination_port_range     = "443"
            source_address_prefix      = "*"
            destination_address_prefix = "*"
          },
        ]
      },
    ]
  }
}

run "rejects_subnet_cidr_outside_vnet" {
  command = plan

  expect_failures = [azurerm_virtual_network.this]

  variables {
    subnets = [
      {
        name           = "snet-outside"
        address_prefix = "192.168.1.0/24"
      },
    ]
  }
}

# A subnet whose first address falls inside the VNet but whose last address extends past it must fail.
# VNet 10.20.0.0/23 covers .0.0-.1.255; the /22 block containing 10.20.1.0 spans .0.0-.3.255.
run "rejects_subnet_extending_past_vnet" {
  command = plan

  expect_failures = [azurerm_virtual_network.this]

  variables {
    address_space = ["10.20.0.0/23"]
    subnets = [
      {
        name           = "snet-oversize"
        address_prefix = "10.20.1.0/22"
      },
    ]
  }
}
