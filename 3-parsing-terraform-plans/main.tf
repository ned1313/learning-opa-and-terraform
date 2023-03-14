provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = var.common_tags
}

resource "azurerm_virtual_network" "main" {
  name                = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  address_space = [var.vnet_address_space]

  tags = var.common_tags
}

resource "azurerm_subnet" "main" {
  for_each             = var.subnets
  name                 = each.key
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [each.value]
}