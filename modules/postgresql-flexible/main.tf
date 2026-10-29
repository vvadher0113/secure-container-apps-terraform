# tflint-ignore: azurerm_resources_missing_prevent_destroy -- backup_retention_days and geo-redundant backups protect data; point-in-time restore is available within the retention window
resource "azurerm_postgresql_flexible_server" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  authentication {
    active_directory_auth_enabled = true
    password_auth_enabled         = false
    tenant_id                     = var.tenant_id
  }

  version    = var.pg_version
  sku_name   = var.sku_name
  storage_mb = var.storage_mb

  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled

  public_network_access_enabled = false

  zone = var.zone

  dynamic "high_availability" {
    for_each = var.high_availability != null ? [var.high_availability] : []
    content {
      mode                      = "ZoneRedundant"
      standby_availability_zone = high_availability.value.standby_availability_zone
    }
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.high_availability == null || !startswith(var.sku_name, "B_")
      error_message = "high_availability is not supported with Burstable (B_) SKUs. Use a General Purpose (GP_) or Memory Optimized (MO_) SKU."
    }
  }
}

resource "azurerm_postgresql_flexible_server_active_directory_administrator" "this" {
  server_name         = azurerm_postgresql_flexible_server.this.name
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id
  object_id           = var.entra_admin.object_id
  principal_name      = var.entra_admin.principal_name
  principal_type      = var.entra_admin.principal_type
}

# Keep transport encryption on. Default is on, but pinning it prevents accidental drift.
resource "azurerm_postgresql_flexible_server_configuration" "require_secure_transport" {
  name      = "require_secure_transport"
  server_id = azurerm_postgresql_flexible_server.this.id
  value     = "on"
}

resource "azurerm_postgresql_flexible_server_configuration" "ssl_min_protocol_version" {
  name      = "ssl_min_protocol_version"
  server_id = azurerm_postgresql_flexible_server.this.id
  value     = "TLSv1.2"
}

resource "azurerm_postgresql_flexible_server_configuration" "log_connections" {
  name      = "log_connections"
  server_id = azurerm_postgresql_flexible_server.this.id
  value     = "on"
}

resource "azurerm_postgresql_flexible_server_configuration" "connection_throttle" {
  name      = "connection_throttle.enable"
  server_id = azurerm_postgresql_flexible_server.this.id
  value     = "on"
}

resource "azurerm_postgresql_flexible_server_configuration" "log_checkpoints" {
  name      = "log_checkpoints"
  server_id = azurerm_postgresql_flexible_server.this.id
  value     = "on"
}

resource "azurerm_postgresql_flexible_server_database" "this" {
  for_each = { for db in var.databases : db.name => db }

  name      = each.value.name
  server_id = azurerm_postgresql_flexible_server.this.id
  charset   = each.value.charset
  collation = each.value.collation
}

module "private_endpoint" {
  source = "../private-endpoint"

  name                 = "pe-${var.name}"
  location             = var.location
  resource_group_name  = var.resource_group_name
  subnet_id            = var.subnet_id
  target_resource_id   = azurerm_postgresql_flexible_server.this.id
  subresource_names    = ["postgresqlServer"]
  private_dns_zone_ids = [var.private_dns_zone_id]
  tags                 = var.tags
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  count = var.diagnostics_enabled ? 1 : 0

  name                       = "diag-${var.name}"
  target_resource_id         = azurerm_postgresql_flexible_server.this.id
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
