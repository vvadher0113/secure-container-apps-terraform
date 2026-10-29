data "azurerm_resource_group" "example" {
  name = "rg-agw-example"
}

module "app_gateway" {
  source = "../../"

  name                      = "agw-goals-dev"
  resource_group_name       = data.azurerm_resource_group.example.name
  location                  = data.azurerm_resource_group.example.location
  subnet_id                 = var.subnet_id
  user_assigned_identity_id = var.user_assigned_identity_id

  backends = {
    web = var.web_fqdn
    api = var.api_fqdn
  }

  # No TLS certificate: HTTP-only listener for demo use.
  # Set tls_certificate_key_vault_secret_id before production use.

  tags = {
    environment = "example"
    managed_by  = "terraform"
  }
}
