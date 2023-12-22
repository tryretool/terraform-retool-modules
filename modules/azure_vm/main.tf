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
    disk_size_gb         = "160"
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
