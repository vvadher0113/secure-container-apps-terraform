resource "azurerm_resource_group" "example" {
  name     = "rg-law-example"
  location = var.location
}

module "log_analytics" {
  source = "../../"

  name                = "law-goals-dev"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  retention_in_days   = 90

  tags = {
    environment = "example"
    managed_by  = "terraform"
  }
}
