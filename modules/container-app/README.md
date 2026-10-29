# module: container-app

Creates a single Azure Container App in Single revision mode with a user-assigned managed
identity, ACR pull via that identity, HTTP ingress, liveness and readiness probes, and
optional Key Vault secret references. No credentials are stored anywhere.

## Usage

```hcl
module "web" {
  source = "./modules/container-app"

  name                         = "app-web"
  resource_group_name          = azurerm_resource_group.main.name
  container_app_environment_id = module.container_apps_env.id
  user_assigned_identity_id    = azurerm_user_assigned_identity.web.id
  acr_login_server             = module.container_registry.login_server
  image                        = "${module.container_registry.login_server}/web:${var.image_tag}"
  target_port                  = 8080
  cpu                          = 0.25
  memory                       = "0.5Gi"

  tags = local.common_tags
}
```

## Ingress and external_enabled

`external_enabled` defaults to `true`. In an environment with
`internal_load_balancer_enabled = true`, "external" means the app is reachable from the
VNet, not from the internet. The public internet has no path to the environment's IP.

Setting `external_enabled = false` creates a *cluster-internal* ingress reachable only from
other apps in the same environment, not from App Gateway. Keep this at `true` unless the app
is a pure backend that must not be reached even by the gateway.

## CPU and memory pairs

CPU and memory are validated independently and then cross-validated as a pair:

| cpu  | memory |
|------|--------|
| 0.25 | 0.5Gi  |
| 0.5  | 1Gi    |
| 0.75 | 1.5Gi  |
| 1.0  | 2Gi    |
| 1.25 | 2.5Gi  |
| 1.5  | 3Gi    |
| 1.75 | 3.5Gi  |
| 2.0  | 4Gi    |

## Secrets

Only Key Vault secret references are accepted. The `value` field in the secrets variable must
be `null`. Each secret requires:
- `name`: the secret name referenced in env vars via `secret_name`
- `key_vault_secret_id`: versioned or versionless Key Vault secret URI
- `identity`: the managed identity resource ID that has Key Vault Secrets User on the secret

```hcl
secrets = [
  {
    name                = "db-token"
    key_vault_secret_id = "https://kv-goals-dev.vault.azure.net/secrets/db-token"
    identity            = azurerm_user_assigned_identity.api.id
  }
]
```

## Probes

Both liveness and readiness probes hit `health_path` (default `/health`) on `target_port`
via HTTP. The liveness probe has an initial delay of 10 seconds to avoid killing the container
before it finishes startup. Adjust `health_path` for apps that use a different endpoint.

## HTTP scale rule

Set `http_scale_concurrent_requests` to trigger a new replica when concurrent HTTP requests
exceed that value:

```hcl
http_scale_concurrent_requests = 10
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.10.0 |
| azurerm | >= 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Container app name (1-32 chars, lowercase). | `string` | n/a | yes |
| resource_group_name | Resource group. | `string` | n/a | yes |
| container_app_environment_id | Container Apps environment resource ID. | `string` | n/a | yes |
| user_assigned_identity_id | Managed identity for app identity and ACR pull. | `string` | n/a | yes |
| acr_login_server | ACR login server (e.g. `acrgoalsdev.azurecr.io`). | `string` | n/a | yes |
| image | Full image reference including tag. | `string` | n/a | yes |
| target_port | TCP port the container listens on. | `number` | n/a | yes |
| cpu | CPU per replica (see allowed pairs table). | `number` | n/a | yes |
| memory | Memory per replica (see allowed pairs table). | `string` | n/a | yes |
| min_replicas | Minimum replica count. | `number` | `0` | no |
| max_replicas | Maximum replica count. | `number` | `3` | no |
| health_path | Probe HTTP path. | `string` | `"/health"` | no |
| external_enabled | Expose to VNet via internal load balancer. | `bool` | `true` | no |
| env_vars | Environment variables. Use secret_name to reference secrets. | `list(object)` | `[]` | no |
| secrets | Key Vault secret references. value must be null. | `list(object)` | `[]` | no |
| http_scale_concurrent_requests | Concurrent request threshold for HTTP scale rule. Null disables. | `number` | `null` | no |
| tags | Tags applied to the container app. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | Resource ID of the container app. |
| name | Name of the container app. |
| fqdn | FQDN of the latest revision. Available after apply; used as App Gateway backend. |
| latest_revision_name | Name of the active revision. Available after apply. |
