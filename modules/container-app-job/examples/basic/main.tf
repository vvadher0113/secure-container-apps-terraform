data "azurerm_resource_group" "example" {
  name = "rg-capp-job-example"
}

module "migrate_job" {
  source = "../../"

  name                         = "job-migrate"
  resource_group_name          = data.azurerm_resource_group.example.name
  location                     = data.azurerm_resource_group.example.location
  container_app_environment_id = var.container_app_environment_id
  user_assigned_identity_id    = var.user_assigned_identity_id
  acr_login_server             = var.acr_login_server
  image                        = var.image
  cpu                          = 0.25
  memory                       = "0.5Gi"

  env_vars = [
    { name = "PGHOST", value = var.pghost },
    { name = "PGDATABASE", value = "appdb" },
  ]

  tags = {
    environment = "example"
    managed_by  = "terraform"
  }
}
