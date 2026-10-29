data "azurerm_resource_group" "example" {
  name = "rg-capp-example"
}

module "web_app" {
  source = "../../"

  name                         = "app-web"
  resource_group_name          = data.azurerm_resource_group.example.name
  container_app_environment_id = var.container_app_environment_id
  user_assigned_identity_id    = var.user_assigned_identity_id
  acr_login_server             = var.acr_login_server
  image                        = var.image
  target_port                  = 8080
  cpu                          = 0.25
  memory                       = "0.5Gi"

  tags = {
    environment = "example"
    managed_by  = "terraform"
  }
}
