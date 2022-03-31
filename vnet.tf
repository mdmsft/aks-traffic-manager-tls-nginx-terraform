resource "azurerm_virtual_network" "main" {
  name                = "vnet-${local.resource_suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [var.address_space]
}

resource "azurerm_network_security_group" "aks_default" {
  name                = "nsg-${local.resource_suffix}-aks-default"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_network_security_group" "aks_main" {
  name                = "nsg-${local.resource_suffix}-aks-main"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "aks_default" {
  name                 = "snet-aks-default"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_resource_group.main.name
  address_prefixes     = [cidrsubnet(var.address_space, 1, 0)]
}

resource "azurerm_subnet" "aks_main" {
  name                 = "snet-aks-main"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_resource_group.main.name
  address_prefixes     = [cidrsubnet(var.address_space, 1, 1)]
}

resource "azurerm_subnet_network_security_group_association" "aks_default" {
  network_security_group_id = azurerm_network_security_group.aks_default.id
  subnet_id                 = azurerm_subnet.aks_default.id
}

resource "azurerm_subnet_network_security_group_association" "aks_main" {
  network_security_group_id = azurerm_network_security_group.aks_main.id
  subnet_id                 = azurerm_subnet.aks_main.id
}
