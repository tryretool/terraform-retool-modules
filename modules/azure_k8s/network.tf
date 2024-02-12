data "azurerm_virtual_network" "selected" {
  name                = var.virtual_network_name
  resource_group_name = data.azurerm_resource_group.selected.name
}

data "azurerm_subnet" "selected" {
  name                 = var.subnet_name
  resource_group_name  = data.azurerm_resource_group.selected.name
  virtual_network_name = data.azurerm_virtual_network.selected.name
}

resource "azurerm_subnet" "this" {
  name                 = "psql-flexible-sn"
  resource_group_name  = data.azurerm_resource_group.selected.name
  virtual_network_name = data.azurerm_virtual_network.selected.name
  address_prefixes     = var.psql_subnet_cidr
  service_endpoints    = ["Microsoft.Storage"]
  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_subnet" "app_gw" {
  count               = var.use_app_gateway ? 1 : 0
  name = "app-gw-sn"
  resource_group_name  = data.azurerm_resource_group.selected.name
  virtual_network_name = data.azurerm_virtual_network.selected.name
  address_prefixes = var.app_gw_subnet_cidr
}

