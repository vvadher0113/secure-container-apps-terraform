# module: app-gateway-waf

Creates an Application Gateway WAF v2 with a WAF policy in Prevention mode, a zone-redundant
static public IP, HTTPS backend settings, per-backend health probes, and path-based routing
to Container Apps. This is the only resource in the architecture that accepts public internet
traffic.

## How App Gateway reaches the Container Apps

App Gateway resolves the Container Apps FQDNs (e.g.
`app-web.cae-goals-dev.bravestone-12345.eastus2.azurecontainerapps.io`) via the private
DNS zone created by the `container-apps-environment` module. That zone is linked to the
VNet, so any resource on the VNet - including App Gateway - can resolve `<app>.<env-domain>`
to the environment's static IP. App Gateway then sends HTTPS traffic to port 443 and the
environment's internal load balancer routes it to the correct app.

Because the environment has `internal_load_balancer_enabled = true`, the Container Apps are
not reachable from the internet even though their ingress uses `external_enabled = true`.
App Gateway is the only path in from outside the VNet.

## Subnet requirements

The `subnet_id` must point to a subnet that is:
- Dedicated to Application Gateway: no other resources can share it.
- At least /24 (recommended) for autoscaling headroom; minimum /26.
- Protected by an NSG that allows `GatewayManager` and `AzureLoadBalancer` inbound on
  ports 65200-65535, and the listener ports (80, 443) from the internet.

## TLS listener

When `tls_certificate_key_vault_secret_id` is set, the module creates:
- An HTTPS 443 listener using the certificate from Key Vault.
- An HTTP 80 listener with a permanent redirect to HTTPS (includes path and query string).

When `tls_certificate_key_vault_secret_id` is empty (the default), a single HTTP 80 listener
is created and routes directly to the url_path_map.

**WARNING:** The HTTP-only configuration is for demo and development purposes only. Do not
use it in production. Set `tls_certificate_key_vault_secret_id` before any public exposure.

## WAF policy

The WAF policy uses `Microsoft_DefaultRuleSet 2.1` in Prevention mode. To switch to
Detection (for initial onboarding), set `waf_mode = "Detection"`. Change it back to
`"Prevention"` before going live.

## Path-based routing

All traffic that does not match a `path_rules` entry goes to `default_backend` (default:
`web`). The default path rule set routes `/api/*` to `api`. Adjust `path_rules` and
`default_backend` to match your application structure.

```hcl
path_rules = [
  { name = "api", paths = ["/api/*"], backend = "api" }
]
default_backend = "web"
```

Every name in `path_rules[*].backend` and in `default_backend` must be a key in the
`backends` map; the module enforces this via lifecycle preconditions.

## Usage

```hcl
module "app_gateway" {
  source = "./modules/app-gateway-waf"

  name                      = "agw-goals-dev"
  resource_group_name       = azurerm_resource_group.main.name
  location                  = azurerm_resource_group.main.location
  subnet_id                 = module.network.subnet_ids["snet-agw"]
  user_assigned_identity_id = azurerm_user_assigned_identity.agw.id

  backends = {
    web = module.web_app.fqdn
    api = module.api_app.fqdn
  }

  tls_certificate_key_vault_secret_id = module.key_vault.tls_cert_secret_id

  diagnostics_enabled        = true
  log_analytics_workspace_id = module.log_analytics.id

  tags = local.common_tags
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.10.0 |
| azurerm | >= 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Application Gateway name (1-80 chars). | `string` | n/a | yes |
| resource_group_name | Resource group. | `string` | n/a | yes |
| location | Azure region. | `string` | n/a | yes |
| subnet_id | Dedicated App Gateway subnet resource ID. | `string` | n/a | yes |
| zones | Availability zones for the public IP and gateway. | `list(string)` | `["1","2","3"]` | no |
| autoscale_min_capacity | Minimum gateway units (>= 0). | `number` | `1` | no |
| autoscale_max_capacity | Maximum gateway units (>= 1). | `number` | `10` | no |
| user_assigned_identity_id | Managed identity for Key Vault certificate access. | `string` | n/a | yes |
| backends | Map of backend name to FQDN. | `map(string)` | n/a | yes |
| default_backend | Backend key for unmatched paths. | `string` | `"web"` | no |
| path_rules | URL path rules applied before the default backend. | `list(object)` | api rule | no |
| health_path | HTTP path used for backend health probes. | `string` | `"/health"` | no |
| waf_mode | WAF policy mode: Prevention or Detection. | `string` | `"Prevention"` | no |
| tls_certificate_key_vault_secret_id | Key Vault secret URI for the TLS certificate. Empty = HTTP-only demo listener. | `string` | `""` | no |
| log_analytics_workspace_id | Log Analytics workspace for diagnostic settings. Required when diagnostics_enabled is true. | `string` | `""` | no |
| diagnostics_enabled | When true, create a diagnostic setting. Requires log_analytics_workspace_id. | `bool` | `false` | no |
| tags | Tags applied to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | Resource ID of the Application Gateway. |
| public_ip_address | Public IP address. Available after apply. |
| waf_policy_id | Resource ID of the WAF policy. |
| waf_mode | Operational mode of the WAF policy (Prevention or Detection). |
