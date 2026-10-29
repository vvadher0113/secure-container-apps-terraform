locals {
  suffix = random_string.suffix.result
  prefix = "${var.app_name}-${var.environment}"

  # Random suffix prevents name collisions and DNS conflicts across subscriptions.
  kv_name   = "kv-${var.app_name}-${var.environment}-${local.suffix}"
  acr_name  = "acr${replace(var.app_name, "-", "")}${replace(var.environment, "-", "")}${local.suffix}"
  psql_name = "psql-${var.app_name}-${var.environment}-${local.suffix}"

  common_tags = {
    app         = var.app_name
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_resource_group" "main" {
  name     = "rg-${local.prefix}"
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_user_assigned_identity" "web" {
  name                = "id-web"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  tags                = local.common_tags
}

resource "azurerm_user_assigned_identity" "api" {
  name                = "id-api"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  tags                = local.common_tags
}

resource "azurerm_user_assigned_identity" "migrate" {
  name                = "id-migrate"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  tags                = local.common_tags
}

resource "azurerm_user_assigned_identity" "agw" {
  name                = "id-agw"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  tags                = local.common_tags
}

module "log_analytics" {
  source = "../../../modules/log-analytics"

  name                = "log-${local.prefix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  retention_in_days   = var.log_analytics_retention_in_days
  tags                = local.common_tags
}

module "network" {
  source = "../../../modules/network"

  name                = "vnet-${local.prefix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  address_space       = var.vnet_address_space

  subnets = [
    {
      name           = "snet-agw"
      address_prefix = "10.20.0.0/24"
      # App Gateway v2 requires these three inbound rules and a GatewayManager rule.
      nsg_rules = [
        {
          name                       = "allow-gateway-manager"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "65200-65535"
          source_address_prefix      = "GatewayManager"
          destination_address_prefix = "*"
        },
        {
          name                       = "allow-azure-load-balancer"
          priority                   = 110
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "*"
          source_port_range          = "*"
          destination_port_range     = "*"
          source_address_prefix      = "AzureLoadBalancer"
          destination_address_prefix = "*"
        },
        {
          name                       = "allow-http"
          priority                   = 200
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "80"
          source_address_prefix      = "Internet"
          destination_address_prefix = "*"
        },
        {
          name                       = "allow-https"
          priority                   = 210
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "443"
          source_address_prefix      = "Internet"
          destination_address_prefix = "*"
        },
      ]
    },
    {
      name           = "snet-aca"
      address_prefix = "10.20.1.0/24"
      delegation = {
        service = "Microsoft.App/environments"
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
      nsg_rules = []
    },
    {
      name                              = "snet-pe"
      address_prefix                    = "10.20.2.0/24"
      private_endpoint_network_policies = "Disabled"
      nsg_rules                         = []
    },
  ]

  tags = local.common_tags
}

module "dns_kv" {
  source = "../../../modules/private-dns-zone"

  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.main.name
  vnet_links = [
    { name = "link-vnet-${local.prefix}", virtual_network_id = module.network.vnet_id }
  ]
  tags = local.common_tags
}

module "dns_acr" {
  source = "../../../modules/private-dns-zone"

  name                = "privatelink.azurecr.io"
  resource_group_name = azurerm_resource_group.main.name
  vnet_links = [
    { name = "link-vnet-${local.prefix}", virtual_network_id = module.network.vnet_id }
  ]
  tags = local.common_tags
}

module "dns_pg" {
  source = "../../../modules/private-dns-zone"

  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.main.name
  vnet_links = [
    { name = "link-vnet-${local.prefix}", virtual_network_id = module.network.vnet_id }
  ]
  tags = local.common_tags
}

module "key_vault" {
  source = "../../../modules/key-vault"

  name                       = local.kv_name
  resource_group_name        = azurerm_resource_group.main.name
  location                   = var.location
  tenant_id                  = var.tenant_id
  soft_delete_retention_days = var.kv_soft_delete_retention_days
  subnet_id                  = module.network.subnet_ids["snet-pe"]
  private_dns_zone_id        = module.dns_kv.zone_id
  diagnostics_enabled        = true
  log_analytics_workspace_id = module.log_analytics.id
  tags                       = local.common_tags
}

module "container_registry" {
  source = "../../../modules/container-registry"

  name                       = local.acr_name
  resource_group_name        = azurerm_resource_group.main.name
  location                   = var.location
  zone_redundancy_enabled    = var.zone_redundancy_enabled
  subnet_id                  = module.network.subnet_ids["snet-pe"]
  private_dns_zone_id        = module.dns_acr.zone_id
  diagnostics_enabled        = true
  log_analytics_workspace_id = module.log_analytics.id
  tags                       = local.common_tags
}

# AcrPull lets each identity pull images without registry credentials.
# Key Vault Secrets User lets id-api read app secrets and id-agw read the TLS cert.

resource "azurerm_role_assignment" "acr_pull_web" {
  scope                = module.container_registry.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.web.principal_id
}

resource "azurerm_role_assignment" "acr_pull_api" {
  scope                = module.container_registry.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.api.principal_id
}

resource "azurerm_role_assignment" "acr_pull_migrate" {
  scope                = module.container_registry.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.migrate.principal_id
}

resource "azurerm_role_assignment" "kv_secrets_api" {
  scope                = module.key_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.api.principal_id
}

resource "azurerm_role_assignment" "kv_secrets_agw" {
  scope                = module.key_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.agw.principal_id
}

# id-migrate is Entra admin; the API connects as id-api with an Entra token issued by pgaadauth_create_principal (registered in-network by the migrate job).

module "postgresql" {
  source = "../../../modules/postgresql-flexible"

  name                = local.psql_name
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  tenant_id           = var.tenant_id

  entra_admin = {
    object_id      = azurerm_user_assigned_identity.migrate.principal_id
    principal_name = azurerm_user_assigned_identity.migrate.name
    principal_type = "ServicePrincipal"
  }

  sku_name              = var.pg_sku_name
  backup_retention_days = var.pg_backup_retention_days

  databases = [
    { name = var.pg_database_name }
  ]

  subnet_id                  = module.network.subnet_ids["snet-pe"]
  private_dns_zone_id        = module.dns_pg.zone_id
  diagnostics_enabled        = true
  log_analytics_workspace_id = module.log_analytics.id
  tags                       = local.common_tags
}

module "cae" {
  source = "../../../modules/container-apps-environment"

  name                     = "cae-${local.prefix}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = var.location
  infrastructure_subnet_id = module.network.subnet_ids["snet-aca"]
  zone_redundancy_enabled  = var.zone_redundancy_enabled
  vnet_links = [
    { name = "link-vnet-${local.prefix}", virtual_network_id = module.network.vnet_id }
  ]
  diagnostics_enabled        = true
  log_analytics_workspace_id = module.log_analytics.id
  tags                       = local.common_tags
}

# depends_on the AcrPull assignment so RBAC propagates before the first image pull.

module "web" {
  source = "../../../modules/container-app"

  name                         = "app-web"
  resource_group_name          = azurerm_resource_group.main.name
  container_app_environment_id = module.cae.id
  user_assigned_identity_id    = azurerm_user_assigned_identity.web.id
  acr_login_server             = module.container_registry.login_server
  image                        = var.app_images.web
  target_port                  = 8080
  cpu                          = 0.25
  memory                       = "0.5Gi"
  tags                         = local.common_tags

  depends_on = [azurerm_role_assignment.acr_pull_web]
}

module "api" {
  source = "../../../modules/container-app"

  name                         = "app-api"
  resource_group_name          = azurerm_resource_group.main.name
  container_app_environment_id = module.cae.id
  user_assigned_identity_id    = azurerm_user_assigned_identity.api.id
  acr_login_server             = module.container_registry.login_server
  image                        = var.app_images.api
  target_port                  = 8000
  cpu                          = 0.25
  memory                       = "0.5Gi"
  tags                         = local.common_tags

  env_vars = [
    { name = "PGHOST", value = module.postgresql.fqdn },
    { name = "PGDATABASE", value = var.pg_database_name },
    { name = "PGUSER", value = azurerm_user_assigned_identity.api.name },
    { name = "AZURE_CLIENT_ID", value = azurerm_user_assigned_identity.api.client_id },
  ]

  depends_on = [
    azurerm_role_assignment.acr_pull_api,
    azurerm_role_assignment.kv_secrets_api,
  ]
}

# Runs SQL migrations and registers the api Entra role via pgaadauth_create_principal.

module "migrate" {
  source = "../../../modules/container-app-job"

  name                         = "job-migrate"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = var.location
  container_app_environment_id = module.cae.id
  user_assigned_identity_id    = azurerm_user_assigned_identity.migrate.id
  acr_login_server             = module.container_registry.login_server
  image                        = var.app_images.migrate
  cpu                          = 0.25
  memory                       = "0.5Gi"
  tags                         = local.common_tags

  env_vars = [
    { name = "PGHOST", value = module.postgresql.fqdn },
    { name = "PGDATABASE", value = var.pg_database_name },
    { name = "PGUSER", value = azurerm_user_assigned_identity.migrate.name },
    { name = "AZURE_CLIENT_ID", value = azurerm_user_assigned_identity.migrate.client_id },
    { name = "APP_ROLE_NAME", value = azurerm_user_assigned_identity.api.name },
    { name = "APP_ROLE_OBJECT_ID", value = azurerm_user_assigned_identity.api.principal_id },
  ]

  depends_on = [azurerm_role_assignment.acr_pull_migrate]
}

# depends_on the Key Vault Secrets User assignment so id-agw can read the TLS cert.

module "app_gateway" {
  source = "../../../modules/app-gateway-waf"

  name                      = "agw-${local.prefix}"
  resource_group_name       = azurerm_resource_group.main.name
  location                  = var.location
  subnet_id                 = module.network.subnet_ids["snet-agw"]
  user_assigned_identity_id = azurerm_user_assigned_identity.agw.id
  autoscale_min_capacity    = var.agw_autoscale_min_capacity
  autoscale_max_capacity    = var.agw_autoscale_max_capacity

  backends = {
    web = module.web.fqdn
    api = module.api.fqdn
  }

  tls_certificate_key_vault_secret_id = var.tls_certificate_key_vault_secret_id
  diagnostics_enabled                 = true
  log_analytics_workspace_id          = module.log_analytics.id
  tags                                = local.common_tags

  depends_on = [azurerm_role_assignment.kv_secrets_agw]
}
