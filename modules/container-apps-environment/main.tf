# tflint-ignore: azurerm_resources_missing_prevent_destroy -- the environment holds no persistent data; apps and jobs are stateless containers
resource "azurerm_container_app_environment" "this" {
  name                           = var.name
  resource_group_name            = var.resource_group_name
  location                       = var.location
  infrastructure_subnet_id       = var.infrastructure_subnet_id
  internal_load_balancer_enabled = true
  zone_redundancy_enabled        = var.zone_redundancy_enabled

  # azure-monitor works when local_authentication_enabled=false; log-analytics mode requires the workspace key.
  logs_destination = "azure-monitor"

  tags = var.tags

  # The Consumption profile must be explicitly declared when using workload profiles mode.
  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }

  dynamic "workload_profile" {
    for_each = { for wp in var.workload_profiles : wp.name => wp }
    content {
      name                  = workload_profile.value.name
      workload_profile_type = workload_profile.value.workload_profile_type
      minimum_count         = workload_profile.value.minimum_count
      maximum_count         = workload_profile.value.maximum_count
    }
  }
}

# Zone named after the environment's default domain so app FQDNs resolve to the static IP inside the VNet.
module "dns_zone" {
  source = "../private-dns-zone"

  name                = azurerm_container_app_environment.this.default_domain
  resource_group_name = var.resource_group_name

  vnet_links = var.vnet_links

  tags = var.tags
}

resource "azurerm_private_dns_a_record" "wildcard" {
  name                = "*"
  private_dns_zone_id = module.dns_zone.zone_id
  ttl                 = 300
  records             = [azurerm_container_app_environment.this.static_ip_address]
  tags                = var.tags
}

resource "azurerm_private_dns_a_record" "apex" {
  name                = "@"
  private_dns_zone_id = module.dns_zone.zone_id
  ttl                 = 300
  records             = [azurerm_container_app_environment.this.static_ip_address]
  tags                = var.tags
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  count = var.diagnostics_enabled ? 1 : 0

  name                       = "diag-${var.name}"
  target_resource_id         = azurerm_container_app_environment.this.id
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
