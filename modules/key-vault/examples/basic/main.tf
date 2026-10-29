resource "azurerm_resource_group" "example" {
  name     = "rg-kv-example"
  location = var.location
}

module "key_vault" {
  source = "../../"

  name                       = "kv-goals-dev"
  resource_group_name        = azurerm_resource_group.example.name
  location                   = azurerm_resource_group.example.location
  tenant_id                  = var.tenant_id
  subnet_id                  = var.subnet_id
  private_dns_zone_id        = var.private_dns_zone_id
  soft_delete_retention_days = var.soft_delete_retention_days

  tags = {
    environment = "example"
    managed_by  = "terraform"
  }
}
