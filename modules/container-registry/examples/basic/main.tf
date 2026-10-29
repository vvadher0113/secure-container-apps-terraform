resource "azurerm_resource_group" "example" {
  name     = "rg-acr-example"
  location = var.location
}

module "container_registry" {
  source = "../../"

  name                = "acrgoalsdev"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  subnet_id           = var.subnet_id
  private_dns_zone_id = var.private_dns_zone_id

  tags = {
    environment = "example"
    managed_by  = "terraform"
  }
}
