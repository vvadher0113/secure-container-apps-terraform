# module: log-analytics

Creates a Log Analytics workspace. Local (shared-key) authentication is disabled by default so
all access requires Entra ID credentials. The default SKU is PerGB2018 and default retention is
30 days; both are configurable.

## Usage

```hcl
module "log_analytics" {
  source = "./modules/log-analytics"

  name                = "law-goals-dev"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  retention_in_days   = 90

  tags = local.common_tags
}
```

## Notes

- **local_authentication_enabled defaults to false:** Shared keys give permanent, broad access to
  the workspace. Disabling local authentication forces all clients to authenticate via Entra ID
  and respects Conditional Access policies.
- **workspace_id vs id:** The `workspace_id` output is the workspace GUID (e.g.
  `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`) used in Log Analytics queries and data source
  configurations. The `id` output is the full Azure resource ID used in diagnostic settings and
  RBAC role assignments.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.10.0 |
| azurerm | >= 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Name of the Log Analytics workspace. | `string` | n/a | yes |
| resource_group_name | Resource group for the workspace. | `string` | n/a | yes |
| location | Azure region. | `string` | n/a | yes |
| sku | Pricing SKU. | `string` | `"PerGB2018"` | no |
| retention_in_days | Data retention in days (30-730). | `number` | `30` | no |
| local_authentication_enabled | Allow shared-key authentication. Defaults to false (Entra ID only). | `bool` | `false` | no |
| tags | Tags applied to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | Resource ID of the Log Analytics workspace. |
| name | Name of the Log Analytics workspace. |
| workspace_id | Workspace GUID used in Log Analytics queries and data source configurations. |
