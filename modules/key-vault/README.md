# module: key-vault

Creates an Azure Key Vault with RBAC authorization, purge protection, a deny-by-default network
ACL, and a private endpoint so the vault is reachable only from within the VNet. Public network
access defaults to off. An optional diagnostic setting ships audit logs to a Log Analytics
workspace.

RBAC authorization is fixed to `true`. Access policies are not supported; assign roles to
identities after deployment.

## Usage

```hcl
module "key_vault" {
  source = "./modules/key-vault"

  name                = "kv-goals-dev"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  subnet_id           = module.network.subnet_ids["snet-pe"]
  private_dns_zone_id = module.dns_zone_kv.zone_id

  diagnostics_enabled        = true
  log_analytics_workspace_id = module.log_analytics.id

  tags = local.common_tags
}
```

## Notes

- **RBAC only:** `rbac_authorization_enabled` is hardcoded to `true`. Assign
  `Key Vault Secrets Officer`, `Key Vault Secrets User`, or equivalent roles to identities.
- **Purge protection:** Defaults to `true`. This is irreversible once set; you cannot disable purge
  protection after enabling it. Required for use as a key store for disk encryption and managed
  HSM.
- **Network ACL:** `default_action = "Deny"` and `bypass = "AzureServices"` are fixed. The vault
  is accessible only via its private endpoint. Azure-trusted services (such as the ARM deployment
  pipeline) bypass the ACL.
- **Private endpoint:** Always created. Targets the `vault` subresource. Provide the subnet and
  the `privatelink.vaultcore.azure.net` DNS zone.
- **Soft-delete and destroy:** When a vault is destroyed with `terraform destroy`, Azure retains it
  in a soft-deleted state for `soft_delete_retention_days` days. During that period, you cannot
  create a new vault with the same name in the same region. Either wait for the retention period
  to expire or purge the soft-deleted vault manually with `az keyvault purge`.
- **Diagnostic setting:** Created when `diagnostics_enabled = true`. Also set
  `log_analytics_workspace_id`; the module enforces this via a lifecycle precondition. Enables
  AuditEvent logs and the allLogs category group.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.10.0 |
| azurerm | >= 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Key Vault name, globally unique. | `string` | n/a | yes |
| resource_group_name | Resource group for all resources. | `string` | n/a | yes |
| location | Azure region. | `string` | n/a | yes |
| tenant_id | Azure Active Directory tenant ID. | `string` | n/a | yes |
| sku_name | Vault SKU: `standard` or `premium`. | `string` | `"standard"` | no |
| purge_protection_enabled | Prevent permanent deletion. | `bool` | `true` | no |
| soft_delete_retention_days | Soft-delete retention (7-90 days). | `number` | `90` | no |
| public_network_access_enabled | Allow public network access. | `bool` | `false` | no |
| subnet_id | Subnet resource ID for the private endpoint. | `string` | n/a | yes |
| private_dns_zone_id | Resource ID of the `privatelink.vaultcore.azure.net` zone. | `string` | n/a | yes |
| log_analytics_workspace_id | Workspace resource ID for diagnostic settings. Required when diagnostics_enabled is true. | `string` | `""` | no |
| diagnostics_enabled | When true, create a diagnostic setting. Requires log_analytics_workspace_id. | `bool` | `false` | no |
| tags | Tags applied to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | Resource ID of the Key Vault. |
| name | Name of the Key Vault. |
| vault_uri | URI of the Key Vault (e.g. `https://kv-goals-dev.vault.azure.net/`). |
| private_endpoint_ip | Private IP address of the Key Vault private endpoint. Available after apply. |
| public_network_access_enabled | Whether public network access is enabled. Always false. |
