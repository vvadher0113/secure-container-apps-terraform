# tflint-ignore: azurerm_resources_missing_prevent_destroy -- the registry stores only CI-managed images that can be rebuilt and re-pushed from source
resource "azurerm_container_registry" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Premium"
  tags                = var.tags

  admin_enabled                 = false
  anonymous_pull_enabled        = false
  zone_redundancy_enabled       = var.zone_redundancy_enabled
  public_network_access_enabled = true
  network_rule_bypass_option    = "AzureServices"
  retention_policy_in_days      = var.retention_days

  # Public access on with default_action=Deny: CI adds a JIT IP rule for the push window, then removes it.
  network_rule_set = [{
    default_action = "Deny"
    ip_rule        = []
  }]
}

module "private_endpoint" {
  source = "../private-endpoint"

  name                 = "pe-${var.name}"
  location             = var.location
  resource_group_name  = var.resource_group_name
  subnet_id            = var.subnet_id
  target_resource_id   = azurerm_container_registry.this.id
  subresource_names    = ["registry"]
  private_dns_zone_ids = [var.private_dns_zone_id]
  tags                 = var.tags
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  count = var.diagnostics_enabled ? 1 : 0

  name                       = "diag-${var.name}"
  target_resource_id         = azurerm_container_registry.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

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
