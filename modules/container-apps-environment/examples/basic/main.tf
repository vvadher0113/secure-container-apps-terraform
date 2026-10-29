resource "azurerm_resource_group" "example" {
  name     = "rg-cae-example"
  location = var.location
}

module "container_apps_environment" {
  source = "../../"

  name                     = "cae-goals-dev"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  infrastructure_subnet_id = var.infrastructure_subnet_id
  vnet_links = [
    {
      name               = "link-vnet-example"
      virtual_network_id = var.vnet_id
    }
  ]

  log_analytics_workspace_id = var.log_analytics_workspace_id

  tags = {
    environment = "example"
    managed_by  = "terraform"
  }
}
