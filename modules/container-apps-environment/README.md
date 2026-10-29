# module: container-apps-environment

Creates an Azure Container Apps environment using workload profiles mode, VNet-integrated
with an internal load balancer so no apps are directly reachable from the internet. The
environment logs to Azure Monitor (not Log Analytics API) so the workspace does not need
local authentication enabled. A private DNS zone and wildcard A record are created so that
internal ingress FQDNs resolve within the VNet.

## Usage

```hcl
module "container_apps_env" {
  source = "./modules/container-apps-environment"

  name                     = "cae-goals-dev"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  infrastructure_subnet_id = module.network.subnet_ids["snet-aca"]
  vnet_links = [
    { name = "link-vnet-goals-dev", virtual_network_id = module.network.vnet_id }
  ]

  diagnostics_enabled        = true
  log_analytics_workspace_id = module.log_analytics.id

  tags = local.common_tags
}
```

## Networking

The environment requires a subnet delegated to `Microsoft.App/environments`. Workload profiles
mode requires at least a **/27** (32 addresses). Larger subnets allow more replicas.

`internal_load_balancer_enabled` is hardcoded to `true`. The environment has no public IP;
access from outside the VNet must go through the Application Gateway WAF.

## DNS

The environment's `default_domain` is computed after creation (it includes a platform-assigned
random component). This module creates:
- A private DNS zone whose name equals `default_domain`
- A wildcard A record (`*`) so all app FQDNs resolve to `static_ip_address`
- An apex A record (`@`) for the bare domain itself
- VNet links for all entries in `vnet_links`

App Gateway uses these records to resolve app backend FQDNs for health probes and routing.

## Logging

`logs_destination = "azure-monitor"` is hardcoded. This routes environment telemetry through
Azure Monitor's pipeline instead of directly to the Log Analytics API. The distinction matters
because the log-analytics destination requires a workspace key, which is unavailable when
`local_authentication_enabled = false`. A diagnostic setting is created separately to ship
`allLogs` to the workspace using the identity-based path.

## Workload profiles

The Consumption profile is always present. Add dedicated profiles for containers that need
predictable CPU and memory:

```hcl
workload_profiles = [
  {
    name                  = "D4"
    workload_profile_type = "D4"
    minimum_count         = 1
    maximum_count         = 3
  }
]
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.10.0 |
| azurerm | >= 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Environment name (1-60 chars, lowercase, hyphens). | `string` | n/a | yes |
| resource_group_name | Resource group for all resources. | `string` | n/a | yes |
| location | Azure region. | `string` | n/a | yes |
| infrastructure_subnet_id | Subnet delegated to Microsoft.App/environments. Minimum /27 for workload profiles. | `string` | n/a | yes |
| zone_redundancy_enabled | Spread replicas across availability zones. | `bool` | `true` | no |
| workload_profiles | Additional dedicated profiles alongside Consumption. | `list(object)` | `[]` | no |
| vnet_links | VNet links for the private DNS zone. Each entry needs a static `name` (for_each key, must be known at plan time) and a `virtual_network_id`. At least one required. | `list(object({name, virtual_network_id}))` | n/a | yes |
| log_analytics_workspace_id | Workspace resource ID for diagnostic settings. Required when diagnostics_enabled is true. | `string` | `""` | no |
| diagnostics_enabled | When true, create a diagnostic setting. Requires log_analytics_workspace_id. | `bool` | `false` | no |
| tags | Tags applied to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | Resource ID of the Container Apps environment. |
| name | Name of the Container Apps environment. |
| default_domain | Default domain assigned by the platform (available after apply). |
| static_ip_address | Static IP of the internal load balancer (available after apply). |
| internal_load_balancer_enabled | Whether the internal load balancer is enabled. Always true. |
