# module: container-registry

Creates an Azure Container Registry (Premium SKU) with admin credentials disabled, a
deny-by-default network rule set, and a private endpoint so the registry is reachable only
from within the VNet. Anonymous pull is disabled. An optional diagnostic setting ships logs to
a Log Analytics workspace.

The public endpoint is enabled but the default network rule denies all traffic. CI pipelines
add a temporary IP rule for the image push window and remove it immediately afterward (see
CI/CD pattern below). This approach allows zero-standing public access while still supporting
automated image builds without requiring a self-hosted runner inside the VNet.

## Usage

```hcl
module "container_registry" {
  source = "./modules/container-registry"

  name                = "acrgoalsdev"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  subnet_id           = module.network.subnet_ids["snet-pe"]
  private_dns_zone_id = module.dns_zone_acr.zone_id

  diagnostics_enabled        = true
  log_analytics_workspace_id = module.log_analytics.id

  tags = local.common_tags
}
```

## CI/CD IP rule pattern

The registry uses `public_network_access_enabled = true` with `network_rule_set.default_action = "Deny"`.
CI opens a temporary rule, pushes the image, then removes the rule:

```yaml
- name: Allow runner IP
  run: az acr network-rule add --name $ACR_NAME --ip-address $(curl -s https://ipinfo.io/ip)

- name: Push image
  run: docker push $ACR_NAME.azurecr.io/myapp:$SHA

- name: Remove runner IP
  if: always()
  run: az acr network-rule remove --name $ACR_NAME --ip-address $(curl -s https://ipinfo.io/ip)
```

The `if: always()` step ensures the IP rule is removed even on push failure. Because the rule is
gone before the next Terraform plan runs, Terraform detects no residual drift on `ip_rule`. The
`network_rule_set` attribute is not excluded from drift detection, so any accidental change to
`default_action` will surface in the next plan.

## Notes

- **SKU:** Fixed at Premium. Premium is required for private endpoints, network rule sets,
  zone redundancy, and retention policies.
- **Admin credentials:** `admin_enabled` is hardcoded to `false`. Grant the `AcrPull` or
  `AcrPush` role to managed identities instead.
- **Anonymous pull:** `anonymous_pull_enabled` is hardcoded to `false`.
- **Network rules:** `default_action = "Deny"` and `network_rule_bypass_option = "AzureServices"`
  are fixed. The only persistent network path is through the private endpoint.
- **Private endpoint:** Always created. Targets the `registry` subresource. Provide the subnet
  and the `privatelink.azurecr.io` DNS zone.
- **Retention:** Untagged manifests are automatically deleted after `retention_days` days
  (default 7).
- **Diagnostic setting:** Created when `diagnostics_enabled = true`. Also set
  `log_analytics_workspace_id`; the module enforces this via a lifecycle precondition.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.10.0 |
| azurerm | >= 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Registry name, globally unique, 5-50 alphanumeric characters. | `string` | n/a | yes |
| resource_group_name | Resource group for all resources. | `string` | n/a | yes |
| location | Azure region. | `string` | n/a | yes |
| zone_redundancy_enabled | Enable zone redundancy (requires availability zones in the region). | `bool` | `true` | no |
| retention_days | Days to retain untagged manifests before deletion (1-365). | `number` | `7` | no |
| subnet_id | Subnet resource ID for the private endpoint. | `string` | n/a | yes |
| private_dns_zone_id | Resource ID of the `privatelink.azurecr.io` zone. | `string` | n/a | yes |
| log_analytics_workspace_id | Workspace resource ID for diagnostic settings. Required when diagnostics_enabled is true. | `string` | `""` | no |
| diagnostics_enabled | When true, create a diagnostic setting. Requires log_analytics_workspace_id. | `bool` | `false` | no |
| tags | Tags applied to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | Resource ID of the container registry. |
| name | Name of the container registry. |
| login_server | Login server hostname (e.g. `acrgoalsdev.azurecr.io`). |
| network_rule_default_action | Default network rule action. Always Deny. |
