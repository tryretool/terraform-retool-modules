resource "azurerm_public_ip" "this" {
  count               = var.use_app_gateway ? 1 : 0
  name                = "retool-pip"
  resource_group_name = data.azurerm_resource_group.selected.name
  location            = data.azurerm_resource_group.selected.location
  sku = "Standard"
  allocation_method   = "Static"
}

locals {
  base_name = "retool"
  backend_address_pool_name      = "${local.base_name}-beap"
  frontend_port_name             = "${local.base_name}-feport"
  frontend_ip_configuration_name = "${local.base_name}-feip"
  http_setting_name              = "${local.base_name}-be-htst"
  listener_name                  = "${local.base_name}-httplstn"
  request_routing_rule_name      = "${local.base_name}-rqrt"
  redirect_configuration_name    = "${local.base_name}-rdrcfg"
}

resource "azurerm_application_gateway" "this" {
  count               = var.use_app_gateway ? 1 : 0
  name                = "retool-appgateway"
  resource_group_name = data.azurerm_resource_group.selected.name
  location            = data.azurerm_resource_group.selected.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "retool-ip-configuration"
    subnet_id = azurerm_subnet.app_gw[0].id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.this[0].id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/path1/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    priority                   = 9
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }
  lifecycle {
    ignore_changes =  all 
  }
}

