resource "azurerm_resource_group" "example" {
  name     = "rg-network-example"
  location = var.location
}

module "network" {
  source = "../../"

  name                = "vnet-goals-dev"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  address_space       = ["10.20.0.0/22"]

  subnets = [
    {
      name           = "snet-agw"
      address_prefix = "10.20.0.0/24"
      # App Gateway WAF v2 requires all four inbound rules below.
      nsg_rules = [
        {
          name                       = "allow-gateway-manager"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "65200-65535"
          source_address_prefix      = "GatewayManager"
          destination_address_prefix = "*"
        },
        {
          name                       = "allow-http-inbound"
          priority                   = 110
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "80"
          source_address_prefix      = "Internet"
          destination_address_prefix = "*"
        },
        {
          name                       = "allow-https-inbound"
          priority                   = 120
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "443"
          source_address_prefix      = "Internet"
          destination_address_prefix = "*"
        },
        {
          name                       = "allow-azure-load-balancer"
          priority                   = 130
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "*"
          source_port_range          = "*"
          destination_port_range     = "*"
          source_address_prefix      = "AzureLoadBalancer"
          destination_address_prefix = "*"
        },
      ]
    },
    {
      name           = "snet-aca"
      address_prefix = "10.20.1.0/24"
      delegation = {
        service = "Microsoft.App/environments"
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    },
    {
      name           = "snet-pe"
      address_prefix = "10.20.2.0/24"
    },
  ]

  tags = {
    environment = "example"
    managed_by  = "terraform"
  }
}
