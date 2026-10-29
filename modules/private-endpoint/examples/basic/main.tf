resource "azurerm_resource_group" "example" {
  name     = "rg-pe-example"
  location = var.location
}

module "private_endpoint" {
  source = "../../"

  name                 = "pe-kv-goals-dev"
  location             = azurerm_resource_group.example.location
  resource_group_name  = azurerm_resource_group.example.name
  subnet_id            = var.subnet_id
  target_resource_id   = var.key_vault_id
  subresource_names    = ["vault"]
  private_dns_zone_ids = [var.private_dns_zone_id]

  tags = {
    environment = "example"
    managed_by  = "terraform"
  }
}
