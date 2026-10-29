locals {
  subnets     = { for s in var.subnets : s.name => s }
  nsg_subnets = { for k, v in local.subnets : k => v if v.nsg_enabled }

  # Integer representations of each subnet's network address, used by the CIDR containment precondition.
  _subnet_network_ints = {
    for name, s in local.subnets : name => (
      tonumber(split(".", cidrhost(s.address_prefix, 0))[0]) * 16777216 +
      tonumber(split(".", cidrhost(s.address_prefix, 0))[1]) * 65536 +
      tonumber(split(".", cidrhost(s.address_prefix, 0))[2]) * 256 +
      tonumber(split(".", cidrhost(s.address_prefix, 0))[3])
    )
  }

  # Integer representation of each subnet's last (broadcast) address, used by the CIDR containment precondition.
  _subnet_last_ints = {
    for name, s in local.subnets : name => (
      local._subnet_network_ints[name] + pow(2, 32 - tonumber(split("/", s.address_prefix)[1])) - 1
    )
  }

  # Integer network address and prefix length for each VNet CIDR, used by the CIDR containment precondition.
  _vnet_ranges = [
    for cidr in var.address_space : {
      prefix_len = tonumber(split("/", cidr)[1])
      network_int = (
        tonumber(split(".", cidrhost(cidr, 0))[0]) * 16777216 +
        tonumber(split(".", cidrhost(cidr, 0))[1]) * 65536 +
        tonumber(split(".", cidrhost(cidr, 0))[2]) * 256 +
        tonumber(split(".", cidrhost(cidr, 0))[3])
      )
    }
  ]
}

resource "azurerm_virtual_network" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.address_space
  tags                = var.tags

  lifecycle {
    precondition {
      condition = alltrue([
        for name, s in local.subnets : anytrue([
          for vnet in local._vnet_ranges : (
            local._subnet_network_ints[name] >= vnet.network_int &&
            local._subnet_last_ints[name] <= vnet.network_int + pow(2, 32 - vnet.prefix_len) - 1
          )
        ])
      ])
      error_message = "Every subnet address_prefix must fall entirely within one of the VNet address_space CIDRs. Containment validation is IPv4 only."
    }
  }
}

resource "azurerm_network_security_group" "this" {
  for_each            = local.nsg_subnets
  name                = "nsg-${each.key}"
  resource_group_name = var.resource_group_name
  location            = var.location

  dynamic "security_rule" {
    for_each = each.value.nsg_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }

  tags = var.tags
}

resource "azurerm_subnet" "this" {
  for_each             = local.subnets
  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [each.value.address_prefix]

  private_endpoint_network_policies = each.value.private_endpoint_network_policies

  dynamic "delegation" {
    for_each = each.value.delegation != null ? [each.value.delegation] : []
    content {
      name = "delegation"
      service_delegation {
        name    = delegation.value.service
        actions = delegation.value.actions
      }
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each                  = local.nsg_subnets
  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = azurerm_network_security_group.this[each.key].id
}
