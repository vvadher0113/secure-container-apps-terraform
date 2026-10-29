# module: postgresql-flexible

Creates an Azure Database for PostgreSQL Flexible Server with Entra-only authentication,
public network access disabled, a private endpoint for VNet-internal connectivity, TLS
enforcement, and one or more databases. Password authentication is hardcoded off; all
connections use an Entra access token as the password.

## Usage

```hcl
module "postgresql" {
  source = "./modules/postgresql-flexible"

  name                = "psql-goals-dev"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tenant_id           = data.azurerm_client_config.current.tenant_id

  entra_admin = {
    object_id      = azurerm_user_assigned_identity.migrate.principal_id
    principal_name = azurerm_user_assigned_identity.migrate.name
    principal_type = "ServicePrincipal"
  }

  databases = [
    { name = "goals" }
  ]

  subnet_id           = module.network.subnet_ids["snet-pe"]
  private_dns_zone_id = module.dns_zone_postgres.zone_id

  diagnostics_enabled        = true
  log_analytics_workspace_id = module.log_analytics.id

  tags = local.common_tags
}
```

## Authentication design

Password authentication (`password_auth_enabled`) is hardcoded to `false`. The server is
created with no `administrator_login` or password. The only way to connect is with an Entra
access token obtained from the managed identity token endpoint.

The API container app acquires a token at runtime using `azure-identity` and passes it as
the password to the PostgreSQL driver. No credentials are stored or distributed.

## Application database roles

Terraform creates the server, the Entra administrator, and the application databases. It
does NOT create application-level database roles or grant table privileges. That work is
done in-network by the `migrate` Container Apps Job, which runs as `id-migrate` (the Entra
admin) and calls `pgaadauth_create_principal` to create the API's role, then runs the SQL
schema migrations. Keeping data-plane configuration inside the private network means
Terraform never needs a network path to the PostgreSQL data plane.

## TLS

`require_secure_transport` is pinned to `on` and `ssl_min_protocol_version` is set to
`TLSv1.2` via `azurerm_postgresql_flexible_server_configuration`. These values are the
Azure defaults, but Terraform manages them explicitly to surface any accidental change in
a plan.

## Immutable settings

`geo_redundant_backup_enabled` cannot be changed after the server is created. Plan
geo-redundancy requirements before the first `terraform apply`. Changing this setting
requires destroying and recreating the server, which loses all data not restored from backup.

## High availability

Set `high_availability` to enable a ZoneRedundant standby replica:

```hcl
high_availability = {
  standby_availability_zone = "2"
}
```

High availability is not supported with Burstable (`B_`) SKUs. `geo_redundant_backup_enabled`
is also not supported with Burstable SKUs.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.10.0 |
| azurerm | >= 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Server name, globally unique, 3-63 lowercase letters/numbers/hyphens. | `string` | n/a | yes |
| resource_group_name | Resource group for all resources. | `string` | n/a | yes |
| location | Azure region. | `string` | n/a | yes |
| tenant_id | Azure AD tenant ID for Entra authentication. | `string` | n/a | yes |
| entra_admin | Identity to set as Entra administrator. object_id, principal_name, principal_type (ServicePrincipal/User/Group). | `object` | n/a | yes |
| pg_version | PostgreSQL major version (11-16). | `string` | `"16"` | no |
| sku_name | Server SKU, e.g. `GP_Standard_D2s_v3`. Must begin with B_, GP_, or MO_. | `string` | `"GP_Standard_D2s_v3"` | no |
| storage_mb | Storage in MiB (minimum 32768). | `number` | `32768` | no |
| backup_retention_days | Backup retention period (7-35 days). | `number` | `7` | no |
| geo_redundant_backup_enabled | Replicate backups to the paired region. Not for Burstable SKUs. | `bool` | `false` | no |
| high_availability | When set, creates a ZoneRedundant standby. Not for Burstable SKUs. | `object({standby_availability_zone})` | `null` | no |
| zone | Availability zone for the primary (e.g. "1"). Null lets Azure choose. | `string` | `null` | no |
| databases | One or more databases to create. At least one required. | `list(object({name, charset, collation}))` | n/a | yes |
| subnet_id | Subnet resource ID for the private endpoint. | `string` | n/a | yes |
| private_dns_zone_id | Resource ID of the `privatelink.postgres.database.azure.com` zone. | `string` | n/a | yes |
| log_analytics_workspace_id | Workspace resource ID for diagnostic settings. Required when diagnostics_enabled is true. | `string` | `""` | no |
| diagnostics_enabled | When true, create a diagnostic setting. Requires log_analytics_workspace_id. | `bool` | `false` | no |
| tags | Tags applied to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | Resource ID of the PostgreSQL Flexible Server. |
| name | Name of the PostgreSQL Flexible Server. |
| fqdn | Fully qualified domain name. Available after apply. |
| database_names | Names of all databases created on the server. |
| public_network_access_enabled | Whether public network access is enabled. Always false. |
| password_auth_enabled | Whether password authentication is enabled. Always false. |
