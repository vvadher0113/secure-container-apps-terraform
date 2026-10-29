# module: network

Creates a virtual network, one NSG per subnet, and the NSG-to-subnet associations. Every subnet
receives an NSG automatically - there is no way to opt out. NSG rules are passed in as a list;
an empty list leaves the NSG with only the implicit platform deny-all rule.

## Usage

```hcl
module "network" {
  source = "./modules/network"

  name                = "vnet-goals-dev"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
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

  tags = local.common_tags
}
```

## Notes

- **App Gateway WAF v2 subnet:** The NSG on `snet-agw` must allow inbound traffic from the
  `GatewayManager` service tag on ports 65200-65535. Without this rule, the gateway enters an
  unhealthy state. See `examples/basic/main.tf` for the full set of required rules.
- **Container Apps environment subnet:** Delegating to `Microsoft.App/environments` is required
  for a workload-profile environment. The required action is
  `Microsoft.Network/virtualNetworks/subnets/join/action`. Azure may add additional actions on
  first use; pin them in `delegation.actions` to prevent plan drift.
- **Private endpoint subnet:** `private_endpoint_network_policies` defaults to `"Enabled"`,
  which causes the subnet NSG to apply to private endpoint traffic. Set it to `"Disabled"` only
  if you need to place private endpoints in a subnet where the NSG should not filter their traffic.
- **Azure-reserved subnets:** Set `nsg_enabled = false` for subnets that Azure refuses to
  associate with an NSG: `GatewaySubnet`, `AzureFirewallSubnet`, `AzureFirewallManagementSubnet`,
  `RouteServerSubnet`. The validation rejects `nsg_enabled = false` on any other name.
- **CIDR containment validation:** A `lifecycle precondition` on the VNet resource verifies that
  every subnet's first and last address fall within one of the VNet's address space CIDRs, causing
  `terraform plan` to fail hard if a subnet is out-of-range. This check is IPv4 only.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.10.0 |
| azurerm | >= 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Name of the virtual network. | `string` | n/a | yes |
| resource_group_name | Resource group for the network resources. | `string` | n/a | yes |
| location | Azure region. | `string` | n/a | yes |
| address_space | One or more CIDR blocks for the VNet address space. | `list(string)` | n/a | yes |
| subnets | Subnet definitions. Each receives an NSG. See object schema below. | `list(object)` | n/a | yes |
| tags | Tags applied to all resources. | `map(string)` | `{}` | no |

### subnets object schema

| Field | Description | Type | Default | Required |
|-------|-------------|------|---------|----------|
| name | Subnet name. Must be unique within the VNet. | `string` | n/a | yes |
| address_prefix | Subnet CIDR, e.g. `10.20.1.0/24`. | `string` | n/a | yes |
| private_endpoint_network_policies | Controls NSG and route table enforcement on private endpoints. | `string` | `"Enabled"` | no |
| delegation.service | Service name to delegate to, e.g. `Microsoft.App/environments`. | `string` | n/a | yes (if delegation set) |
| delegation.actions | List of delegation actions. Pin to prevent plan drift. | `list(string)` | `null` | no |
| nsg_rules | Inbound or outbound NSG rules. See NSG rule schema below. | `list(object)` | `[]` | no |
| nsg_enabled | Create and associate an NSG for this subnet. Must be false only for Azure-reserved subnet names that reject NSG associations. | `bool` | `true` | no |

### nsg_rules object schema

| Field | Description | Type |
|-------|-------------|------|
| name | Rule name, unique within the NSG. | `string` |
| priority | Rule priority, 100-4096. | `number` |
| direction | `Inbound` or `Outbound`. | `string` |
| access | `Allow` or `Deny`. | `string` |
| protocol | `Tcp`, `Udp`, `Icmp`, `Esp`, `Ah`, or `*`. | `string` |
| source_port_range | Source port or range, e.g. `*` or `1024-65535`. | `string` |
| destination_port_range | Destination port or range, e.g. `443` or `65200-65535`. | `string` |
| source_address_prefix | CIDR, service tag, or `*`. | `string` |
| destination_address_prefix | CIDR, service tag, or `*`. | `string` |

## Outputs

| Name | Description |
|------|-------------|
| vnet_id | Resource ID of the virtual network. |
| vnet_name | Name of the virtual network. |
| subnet_ids | Map of subnet name to subnet resource ID. |
| nsg_ids | Map of subnet name to NSG resource ID. |
