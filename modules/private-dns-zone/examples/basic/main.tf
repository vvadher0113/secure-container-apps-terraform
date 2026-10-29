resource "azurerm_resource_group" "example" {
  name     = "rg-dns-example"
  location = var.location
}

module "private_dns_zone" {
  source = "../../"

  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.example.name

  vnet_links = [
    {
      name               = "link-goals-dev"
      virtual_network_id = var.vnet_id
    },
  ]

  tags = {
    environment = "example"
    managed_by  = "terraform"
  }
}
