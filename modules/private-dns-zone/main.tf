resource "azurerm_private_dns_zone" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each = { for l in var.vnet_links : l.name => l }

  name                 = each.value.name
  private_dns_zone_id  = azurerm_private_dns_zone.this.id
  virtual_network_id   = each.value.virtual_network_id
  registration_enabled = each.value.registration_enabled
  tags                 = var.tags
}
