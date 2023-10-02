terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.74"
    }
  }
}

locals {
  flat_security_rules = {
    for rule in var.security_rules :
    rule.name => rule
  }
}

data "azurerm_resource_group" "selected" {
  name = var.resource_group_name
}

data "azurerm_virtual_network" "selected" {
  name                = var.virtual_network_name
  resource_group_name = data.azurerm_resource_group.selected.name
}

data "azurerm_subnet" "selected" {
  name                 = var.subnet_name
  resource_group_name  = data.azurerm_resource_group.selected.name
  virtual_network_name = data.azurerm_virtual_network.selected.name
}

resource "azurerm_public_ip" "this" {
  name                = "retool_public_ip"
  resource_group_name = data.azurerm_resource_group.selected.name
  location            = data.azurerm_resource_group.selected.location
  allocation_method   = "Dynamic"
  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_network_interface" "this" {
  name                = "retoolni"
  location            = data.azurerm_resource_group.selected.location
  resource_group_name = data.azurerm_resource_group.selected.name

  ip_configuration {
    name                          = "retool-ni-config"
    subnet_id                     = data.azurerm_subnet.selected.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.this.id
  }
}

resource "azurerm_network_security_group" "this" {
  name                = "retool-sg"
  location            = data.azurerm_resource_group.selected.location
  resource_group_name = data.azurerm_resource_group.selected.name
}

resource "azurerm_network_security_rule" "this" {
  for_each                    = local.flat_security_rules
  name                        = each.value.name
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
  resource_group_name         = data.azurerm_resource_group.selected.name
  network_security_group_name = azurerm_network_security_group.this.name


}

resource "azurerm_network_interface_security_group_association" "this" {
  network_interface_id      = azurerm_network_interface.this.id
  network_security_group_id = azurerm_network_security_group.this.id
}

resource "azurerm_linux_virtual_machine" "this" {
  name                = "retool"
  resource_group_name = data.azurerm_resource_group.selected.name
  location            = data.azurerm_resource_group.selected.location
  size                = var.instance_size
  admin_username      = "retooladmin"
  network_interface_ids = [
    azurerm_network_interface.this.id,
  ]

  admin_ssh_key {
    username   = "retooladmin"
    public_key = file(var.ssh_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}


resource "azurerm_virtual_machine_extension" "this" {
  name                 = "retool"
  virtual_machine_id   = azurerm_linux_virtual_machine.this.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
  {
    "script": "${base64encode(templatefile("vm_script.sh", {
  version_number = "${var.version_number}"
}))}"
  }
  SETTINGS

}

resource "azurerm_subnet" "this" {
  count = var.external_psql ? 1 : 0
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
resource "azurerm_private_dns_zone" "this" {
  count = var.external_psql ? 1 : 0
  name                = "retool.postgres.database.azure.com"
  resource_group_name = data.azurerm_resource_group.selected.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  count = var.external_psql ? 1 : 0
  name                  = "retool-internal.com"
  private_dns_zone_name = azurerm_private_dns_zone.this[0].name
  virtual_network_id    = data.azurerm_virtual_network.selected.id
  resource_group_name   = data.azurerm_resource_group.selected.name
}

resource "azurerm_postgresql_flexible_server" "this" {
  count = var.external_psql ? 1 : 0
  name                   = "retool-psqlflexibleserver"
  resource_group_name    = data.azurerm_resource_group.selected.name
  location               = data.azurerm_resource_group.selected.location
  version                = "12"
  delegated_subnet_id    = azurerm_subnet.this[0].id
  private_dns_zone_id    = azurerm_private_dns_zone.this[0].id
  administrator_login    = var.psql_user
  administrator_password = var.psql_password
  zone                   = "1"

  storage_mb = 32768

  sku_name   = var.db_instance_size
  depends_on = [azurerm_private_dns_zone_virtual_network_link.this[0]]

}

resource "azurerm_postgresql_flexible_server_database" "this" {
  count = var.external_psql ? 1 : 0
  name      = "retool"
  server_id = azurerm_postgresql_flexible_server.this[0].id
  collation = "en_US.utf8"
  charset   = "utf8"
}