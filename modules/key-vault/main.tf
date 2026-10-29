# tflint-ignore: azurerm_resources_missing_prevent_destroy -- purge protection and soft-delete retain vault objects for soft_delete_retention_days days after any destroy
resource "azurerm_key_vault" "this" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = var.tenant_id
  sku_name                      = var.sku_name
  purge_protection_enabled      = var.purge_protection_enabled
  soft_delete_retention_days    = var.soft_delete_retention_days
  public_network_access_enabled = var.public_network_access_enabled
  rbac_authorization_enabled    = true

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }

  tags = var.tags
}

module "private_endpoint" {
  source = "../private-endpoint"

  name                 = "pe-${var.name}"
  location             = var.location
  resource_group_name  = var.resource_group_name
  subnet_id            = var.subnet_id
  target_resource_id   = azurerm_key_vault.this.id
  subresource_names    = ["vault"]
  private_dns_zone_ids = [var.private_dns_zone_id]
  tags                 = var.tags
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  count = var.diagnostics_enabled ? 1 : 0

  name                       = "diag-${var.name}"
  target_resource_id         = azurerm_key_vault.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_log {
    category_group = "allLogs"
  }

  lifecycle {
    precondition {
      condition     = !var.diagnostics_enabled || var.log_analytics_workspace_id != ""
      error_message = "log_analytics_workspace_id must be set when diagnostics_enabled is true."
    }
  }
}
