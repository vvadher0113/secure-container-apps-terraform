# module: container-app-job

Creates a manually triggered Azure Container Apps Job with a user-assigned managed identity
and ACR pull via that identity. No credentials are stored anywhere.

## Purpose: the migrate job

This module is designed for the `migrate` job that runs SQL migrations and creates the
API's database role. It does this inside the private VNet as the PostgreSQL Entra
administrator (`id-migrate`), keeping all data-plane setup off the public internet:

1. Terraform applies the infrastructure (server, private endpoint, Entra admin assignment).
2. After apply, the caller starts the job: `az containerapp job start --name job-migrate-goals-dev --resource-group rg-goals-dev`
3. The job container connects to PostgreSQL using `id-migrate`'s Entra token, runs the
   Alembic migrations, and calls `pgaadauth_create_principal` to register `id-api` as a
   database role. The API then connects with its own Entra token - no password ever exists.
4. The job exits. Subsequent runs are idempotent (Alembic tracks applied migrations).

## Usage

```hcl
module "migrate_job" {
  source = "./modules/container-app-job"

  name                         = "job-migrate-goals-dev"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  container_app_environment_id = module.container_apps_env.id
  user_assigned_identity_id    = azurerm_user_assigned_identity.migrate.id
  acr_login_server             = module.container_registry.login_server
  image                        = "${module.container_registry.login_server}/migrate:${var.image_tag}"
  cpu                          = 0.25
  memory                       = "0.5Gi"

  env_vars = [
    { name = "PGHOST", value = module.postgresql.fqdn },
    { name = "PGDATABASE", value = "appdb" },
  ]

  tags = local.common_tags
}
```

Start the job after `terraform apply`:

```bash
az containerapp job start \
  --name job-migrate-goals-dev \
  --resource-group rg-goals-dev
```

## Trigger

Only `manual_trigger_config` is configured (`parallelism = 1`,
`replica_completion_count = 1`). There is no schedule or event trigger. Each run
is one replica that must complete successfully. Use `replica_retry_limit` (default 1)
to allow one automatic retry on transient failures.

## CPU and memory pairs

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

Only Key Vault secret references are accepted. The `value` field must be `null`. Each
secret requires:
- `name`: the secret name referenced in env vars via `secret_name`
- `key_vault_secret_id`: versioned or versionless Key Vault secret URI
- `identity`: the managed identity resource ID that has Key Vault Secrets User on the secret

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.10.0 |
| azurerm | >= 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Job name (1-32 chars, lowercase). | `string` | n/a | yes |
| resource_group_name | Resource group. | `string` | n/a | yes |
| location | Azure region. | `string` | n/a | yes |
| container_app_environment_id | Container Apps environment resource ID. | `string` | n/a | yes |
| workload_profile_name | Workload profile name in the environment. | `string` | `"Consumption"` | no |
| user_assigned_identity_id | Managed identity for job identity and ACR pull. | `string` | n/a | yes |
| acr_login_server | ACR login server (e.g. `acrgoalsdev.azurecr.io`). | `string` | n/a | yes |
| image | Full image reference including tag. | `string` | n/a | yes |
| cpu | CPU per replica (see allowed pairs table). | `number` | n/a | yes |
| memory | Memory per replica (see allowed pairs table). | `string` | n/a | yes |
| env_vars | Environment variables. Use secret_name to reference secrets. | `list(object)` | `[]` | no |
| command | Override container entrypoint. Null uses the image default. | `list(string)` | `null` | no |
| args | Arguments passed to the container command. | `list(string)` | `null` | no |
| replica_timeout_in_seconds | Max seconds a replica may run before termination. 60-3600. | `number` | `600` | no |
| replica_retry_limit | Max retries for a failed replica. 0-5. | `number` | `1` | no |
| secrets | Key Vault secret references. value must be null. | `list(object)` | `[]` | no |
| tags | Tags applied to the job. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | Resource ID of the container app job. |
| name | Name of the container app job. |
