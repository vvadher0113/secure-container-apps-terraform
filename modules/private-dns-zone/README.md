# module: private-dns-zone

Creates a private DNS zone and one virtual network link per entry in `vnet_links`. At least one
link is required - a zone with no links is unreachable from any VNet. Auto-registration of VM DNS
records is disabled by default (`registration_enabled = false`) to prevent VM hostnames from
polluting the zone namespace.

## Usage

```hcl
module "private_dns_zone" {
  source = "./modules/private-dns-zone"

  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.main.name

  vnet_links = [
    {
      name               = "link-goals-dev"
      virtual_network_id = module.network.vnet_id
    },
  ]

  tags = local.common_tags
}
```

## Notes

- **At least one VNet link required:** The module validates that `vnet_links` is non-empty. A
  private DNS zone with no VNet links cannot resolve names from within any VNet.
- **registration_enabled defaults to false:** Automatic DNS registration records the private IP
  of every VM in the linked VNet. For shared private endpoint zones this would add unwanted
  records; leave it false unless you explicitly need VM auto-registration.
- **Multiple zones:** Deploy one instance of this module per zone name. Each zone is independent;
  a single VNet can be linked to many zones.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.10.0 |
| azurerm | >= 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Private DNS zone name, e.g. `privatelink.postgres.database.azure.com`. | `string` | n/a | yes |
| resource_group_name | Resource group for the private DNS zone. | `string` | n/a | yes |
| vnet_links | VNet links. At least one required. See object schema below. | `list(object)` | n/a | yes |
| tags | Tags applied to all resources. | `map(string)` | `{}` | no |

### vnet_links object schema

| Field | Description | Type | Default | Required |
|-------|-------------|------|---------|----------|
| name | Link name, unique within the zone. | `string` | n/a | yes |
| virtual_network_id | Resource ID of the VNet to link. | `string` | n/a | yes |
| registration_enabled | Enable auto-registration of VM DNS records. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| zone_id | Resource ID of the private DNS zone. |
| zone_name | Name of the private DNS zone. |
| vnet_link_ids | Map of VNet link name to resource ID. |
