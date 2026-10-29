# tflint-ignore: azurerm_resources_missing_prevent_destroy -- container apps hold no persistent state; images are immutable and can be redeployed
resource "azurerm_container_app" "this" {
  name                         = var.name
  resource_group_name          = var.resource_group_name
  container_app_environment_id = var.container_app_environment_id
  revision_mode                = "Single"
  tags                         = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [var.user_assigned_identity_id]
  }

  registry {
    server   = var.acr_login_server
    identity = var.user_assigned_identity_id
  }

  dynamic "secret" {
    for_each = { for s in var.secrets : s.name => s }
    content {
      name                = secret.value.name
      key_vault_secret_id = secret.value.key_vault_secret_id
      identity            = secret.value.identity
    }
  }

  ingress {
    # external_enabled = true makes the app reachable from the VNet.
    # The environment has internal_load_balancer_enabled = true, so "external" means
    # VNet-only, not internet-facing. false would make the app unreachable from App Gateway.
    external_enabled           = var.external_enabled
    target_port                = var.target_port
    allow_insecure_connections = false
    transport                  = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    container {
      name   = var.name
      image  = var.image
      cpu    = var.cpu
      memory = var.memory

      dynamic "env" {
        for_each = var.env_vars
        content {
          name        = env.value.name
          value       = env.value.value
          secret_name = env.value.secret_name
        }
      }

      liveness_probe {
        port             = var.target_port
        transport        = "HTTP"
        path             = var.health_path
        initial_delay    = 10
        interval_seconds = 30
      }

      readiness_probe {
        port             = var.target_port
        transport        = "HTTP"
        path             = var.health_path
        interval_seconds = 10
      }
    }

    dynamic "http_scale_rule" {
      for_each = var.http_scale_concurrent_requests != null ? [var.http_scale_concurrent_requests] : []
      content {
        name                = "http-scale"
        concurrent_requests = tostring(http_scale_rule.value)
      }
    }
  }

  lifecycle {
    precondition {
      condition = contains([
        { cpu = 0.25, memory = "0.5Gi" },
        { cpu = 0.5, memory = "1Gi" },
        { cpu = 0.75, memory = "1.5Gi" },
        { cpu = 1.0, memory = "2Gi" },
        { cpu = 1.25, memory = "2.5Gi" },
        { cpu = 1.5, memory = "3Gi" },
        { cpu = 1.75, memory = "3.5Gi" },
        { cpu = 2.0, memory = "4Gi" },
      ], { cpu = var.cpu, memory = var.memory })
      error_message = "cpu and memory must form a valid pair: 0.25/0.5Gi, 0.5/1Gi, 0.75/1.5Gi, 1.0/2Gi, 1.25/2.5Gi, 1.5/3Gi, 1.75/3.5Gi, 2.0/4Gi."
    }
  }
}
