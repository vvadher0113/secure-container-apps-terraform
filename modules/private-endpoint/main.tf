resource "azurerm_private_endpoint" "this" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  subnet_id                     = var.subnet_id
  custom_network_interface_name = var.custom_network_interface_name
  tags                          = var.tags

  private_service_connection {
    name                           = "${var.name}-psc"
    private_connection_resource_id = var.target_resource_id
    subresource_names              = var.subresource_names
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = var.private_dns_zone_ids
  }
}
