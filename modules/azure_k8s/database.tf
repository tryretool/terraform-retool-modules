resource "random_password" "psql_password" {
  length  = 16
  special = true
}
resource "random_password" "temporal_password" {
  length  = 16
  special = true
}


resource "azurerm_private_dns_zone" "this" {
  name                = "retool-dbs.postgres.database.azure.com"
  resource_group_name = data.azurerm_resource_group.selected.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  name                  = "retool-internal.com"
  private_dns_zone_name = azurerm_private_dns_zone.this.name
  virtual_network_id    = data.azurerm_virtual_network.selected.id
  resource_group_name   = data.azurerm_resource_group.selected.name
}

resource "azurerm_postgresql_flexible_server" "this" {
  name                   = var.psql_db_name
  resource_group_name    = data.azurerm_resource_group.selected.name
  location               = data.azurerm_resource_group.selected.location
  version                = "12"
  delegated_subnet_id    = azurerm_subnet.this.id
  private_dns_zone_id    = azurerm_private_dns_zone.this.id
  administrator_login    = var.psql_user
  administrator_password = random_password.psql_password.result
  zone                   = "1"

  storage_mb = 32768

  sku_name   = var.db_instance_size
  depends_on = [azurerm_private_dns_zone_virtual_network_link.this]

}

resource "azurerm_postgresql_flexible_server_database" "this" {
  name      = "retool"
  server_id = azurerm_postgresql_flexible_server.this.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

resource "azurerm_postgresql_flexible_server_configuration" "this" {
  name      = "azure.extensions"
  server_id = azurerm_postgresql_flexible_server.this.id
  value     = "UUID-OSSP"
}

resource "azurerm_postgresql_flexible_server" "temporal" {
  count                  = var.local_temporal ? 1 : 0
  name                   = var.temporal_db_name
  resource_group_name    = data.azurerm_resource_group.selected.name
  location               = data.azurerm_resource_group.selected.location
  version                = "12"
  delegated_subnet_id    = azurerm_subnet.this.id
  private_dns_zone_id    = azurerm_private_dns_zone.this.id
  administrator_login    = var.temporal_user
  administrator_password = random_password.temporal_password.result
  zone                   = "1"

  storage_mb = 32768

  sku_name   = var.db_instance_size
  depends_on = [azurerm_private_dns_zone_virtual_network_link.this]

}

# resource "azurerm_postgresql_flexible_server_database" "temporal" {
#   name      = "temporal"
#   server_id = azurerm_postgresql_flexible_server.temporal.id
#   collation = "en_US.utf8"
#   charset   = "utf8"
# }

# resource "azurerm_postgresql_flexible_server_database" "temporal_vis" {
#   name      = "temporal_vis"
#   server_id = azurerm_postgresql_flexible_server.temporal.id
#   collation = "en_US.utf8"
#   charset   = "utf8"
# }

resource "azurerm_postgresql_flexible_server_configuration" "temporal" {
  count     = var.local_temporal ? 1 : 0
  name      = "azure.extensions"
  server_id = azurerm_postgresql_flexible_server.temporal[0].id
  value     = "UUID-OSSP"
}