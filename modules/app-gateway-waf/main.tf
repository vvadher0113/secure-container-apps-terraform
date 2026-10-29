locals {
  use_tls = var.tls_certificate_key_vault_secret_id != ""

  frontend_public_name = "frontend-public"
  port_http_name       = "port-http"
  port_https_name      = "port-https"
  listener_http_name   = "listener-http"
  listener_https_name  = "listener-https"
  ssl_cert_name        = "ssl-cert"
  redirect_name        = "redirect-http-to-https"
  path_map_name        = "path-map"
  main_listener        = local.use_tls ? local.listener_https_name : local.listener_http_name
  main_rule_name       = local.use_tls ? "rule-https" : "rule-http"
}

resource "azurerm_web_application_firewall_policy" "this" {
  name                = "${var.name}-waf-policy"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  policy_settings {
    enabled            = true
    mode               = var.waf_mode
    request_body_check = true
  }

  managed_rules {
    managed_rule_set {
      type    = "Microsoft_DefaultRuleSet"
      version = "2.1"
    }
  }
}

resource "azurerm_public_ip" "this" {
  name                = "${var.name}-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.zones
  tags                = var.tags
}

# tflint-ignore: azurerm_resources_missing_prevent_destroy -- configuration-only; SSL certs reference Key Vault and backend FQDNs can be reconfigured
resource "azurerm_application_gateway" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  zones               = var.zones
  firewall_policy_id  = azurerm_web_application_firewall_policy.this.id
  tags                = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [var.user_assigned_identity_id]
  }

  sku {
    name = "WAF_v2"
    tier = "WAF_v2"
  }

  autoscale_configuration {
    min_capacity = var.autoscale_min_capacity
    max_capacity = var.autoscale_max_capacity
  }

  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101S"
  }

  gateway_ip_configuration {
    name      = "gateway-ip-config"
    subnet_id = var.subnet_id
  }

  frontend_ip_configuration {
    name                 = local.frontend_public_name
    public_ip_address_id = azurerm_public_ip.this.id
  }

  frontend_port {
    name = local.port_http_name
    port = 80
  }

  dynamic "frontend_port" {
    for_each = local.use_tls ? [1] : []
    content {
      name = local.port_https_name
      port = 443
    }
  }

  dynamic "ssl_certificate" {
    for_each = local.use_tls ? [1] : []
    content {
      name                = local.ssl_cert_name
      key_vault_secret_id = var.tls_certificate_key_vault_secret_id
    }
  }

  dynamic "backend_address_pool" {
    for_each = var.backends
    content {
      name  = "backend-${backend_address_pool.key}"
      fqdns = [backend_address_pool.value]
    }
  }

  dynamic "backend_http_settings" {
    for_each = var.backends
    content {
      name                                = "settings-${backend_http_settings.key}"
      cookie_based_affinity               = "Disabled"
      port                                = 443
      protocol                            = "Https"
      pick_host_name_from_backend_address = true
      request_timeout                     = 30
      probe_name                          = "probe-${backend_http_settings.key}"
    }
  }

  dynamic "probe" {
    for_each = var.backends
    content {
      name                                      = "probe-${probe.key}"
      protocol                                  = "Https"
      path                                      = var.health_path
      pick_host_name_from_backend_http_settings = true
      interval                                  = 30
      timeout                                   = 30
      unhealthy_threshold                       = 3

      match {
        status_code = ["200-399"]
      }
    }
  }

  http_listener {
    name                           = local.listener_http_name
    frontend_ip_configuration_name = local.frontend_public_name
    frontend_port_name             = local.port_http_name
    protocol                       = "Http"
  }

  dynamic "http_listener" {
    for_each = local.use_tls ? [1] : []
    content {
      name                           = local.listener_https_name
      frontend_ip_configuration_name = local.frontend_public_name
      frontend_port_name             = local.port_https_name
      protocol                       = "Https"
      ssl_certificate_name           = local.ssl_cert_name
    }
  }

  dynamic "redirect_configuration" {
    for_each = local.use_tls ? [1] : []
    content {
      name                 = local.redirect_name
      redirect_type        = "Permanent"
      target_listener_name = local.listener_https_name
      include_path         = true
      include_query_string = true
    }
  }

  url_path_map {
    name                               = local.path_map_name
    default_backend_address_pool_name  = "backend-${var.default_backend}"
    default_backend_http_settings_name = "settings-${var.default_backend}"

    dynamic "path_rule" {
      for_each = { for pr in var.path_rules : pr.name => pr }
      content {
        name                       = path_rule.key
        paths                      = path_rule.value.paths
        backend_address_pool_name  = "backend-${path_rule.value.backend}"
        backend_http_settings_name = "settings-${path_rule.value.backend}"
      }
    }
  }

  request_routing_rule {
    name               = local.main_rule_name
    rule_type          = "PathBasedRouting"
    http_listener_name = local.main_listener
    url_path_map_name  = local.path_map_name
    priority           = 100
  }

  dynamic "request_routing_rule" {
    for_each = local.use_tls ? [1] : []
    content {
      name                        = "rule-redirect"
      rule_type                   = "Basic"
      http_listener_name          = local.listener_http_name
      redirect_configuration_name = local.redirect_name
      priority                    = 200
    }
  }

  lifecycle {
    precondition {
      condition     = var.autoscale_min_capacity <= var.autoscale_max_capacity
      error_message = "autoscale_min_capacity must be less than or equal to autoscale_max_capacity."
    }

    precondition {
      condition     = contains(keys(var.backends), var.default_backend)
      error_message = "default_backend must be a key in the backends map."
    }

    precondition {
      condition = alltrue([
        for pr in var.path_rules : contains(keys(var.backends), pr.backend)
      ])
      error_message = "Each path_rules entry backend must be a key in the backends map."
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  count = var.diagnostics_enabled ? 1 : 0

  name                       = "diag-${var.name}"
  target_resource_id         = azurerm_application_gateway.this.id
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
