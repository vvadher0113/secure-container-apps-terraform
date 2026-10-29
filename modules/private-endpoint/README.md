# module: private-endpoint

Creates a private endpoint and always attaches a DNS zone group so the target resource resolves
to its private IP address within the VNet. The private service connection uses automatic approval
(`is_manual_connection = false`); manual approval is not supported by this module.

Reused by every PaaS module in this repo: Key Vault, ACR, PostgreSQL Flexible Server, Storage
Account (state bootstrap), and the Container Apps environment.

## Usage

```hcl
module "pe_key_vault" {
  source = "./modules/private-endpoint"

  name                = "pe-kv-goals-dev"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = module.network.subnet_ids["snet-pe"]
  target_resource_id  = module.key_vault.id
  subresource_names   = ["vault"]
  private_dns_zone_ids = [module.dns_zone_kv.zone_id]

  tags = local.common_tags
}
```

## Supported subresource names

| Value | Target resource |
|-------|----------------|
| `vault` | Azure Key Vault |
| `registry` | Azure Container Registry |
| `postgresqlServer` | Azure Database for PostgreSQL Flexible Server |
| `blob` | Azure Storage Account (Blob) |
| `managedEnvironments` | Azure Container Apps Environment |

## Notes

- **DNS zone group required:** `private_dns_zone_ids` must contain at least one entry. An endpoint
  without a DNS zone group gets a private IP but DNS continues to resolve to the public hostname,
  so private name resolution never works.
- **Automatic approval only:** `is_manual_connection` is hardcoded to `false`. Manual connections
  require out-of-band approval and are not appropriate for infrastructure-as-code deployments.
- **One subresource per endpoint:** Azure generally supports one subresource name per endpoint.
  The `subresource_names` list accepts multiple values in the schema but in practice each endpoint
  targets one subresource.
- **Custom NIC name:** `custom_network_interface_name` is optional. When omitted, Azure assigns a
  name automatically. Providing a name makes the NIC identifiable in the portal.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.10.0 |
| azurerm | >= 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Name of the private endpoint. | `string` | n/a | yes |
| location | Azure region for the private endpoint. | `string` | n/a | yes |
| resource_group_name | Resource group for the private endpoint. | `string` | n/a | yes |
| subnet_id | Resource ID of the subnet for the endpoint. | `string` | n/a | yes |
| target_resource_id | Resource ID of the Azure resource to connect to. | `string` | n/a | yes |
| subresource_names | Subresource names for the connection. See table above. | `list(string)` | n/a | yes |
| private_dns_zone_ids | Resource IDs of the private DNS zones for the DNS zone group. At least one required. | `list(string)` | n/a | yes |
| custom_network_interface_name | Custom name for the attached NIC. Null assigns a name automatically. | `string` | `null` | no |
| tags | Tags applied to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | Resource ID of the private endpoint. |
| private_ip_address | Private IP address assigned to the endpoint. Available after apply. |
| network_interface_id | Resource ID of the network interface attached to the private endpoint. Available after apply. |
