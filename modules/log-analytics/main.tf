resource "azurerm_log_analytics_workspace" "this" {
  name                         = var.name
  location                     = var.location
  resource_group_name          = var.resource_group_name
  sku                          = var.sku
  retention_in_days            = var.retention_in_days
  local_authentication_enabled = var.local_authentication_enabled
  tags                         = var.tags
}
