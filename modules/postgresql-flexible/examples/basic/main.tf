resource "azurerm_resource_group" "example" {
  name     = "rg-psql-example"
  location = var.location
}

module "postgresql" {
  source = "../../"

  name                = "psql-goals-dev"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  tenant_id           = var.tenant_id

  entra_admin = {
    object_id      = var.entra_admin_object_id
    principal_name = var.entra_admin_principal_name
    principal_type = "ServicePrincipal"
  }

  databases = [
    { name = "goals" }
  ]

  subnet_id           = var.subnet_id
  private_dns_zone_id = var.private_dns_zone_id

  tags = {
    environment = "example"
    managed_by  = "terraform"
  }
}
