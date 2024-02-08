terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.74"
    }
  }
}

data "azurerm_resource_group" "selected" {
  name = var.resource_group_name
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "retool"
  location            = data.azurerm_resource_group.selected.location
  resource_group_name = data.azurerm_resource_group.selected.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_kubernetes_cluster" "this" {
  name                    = "retool-cluster"
  location                = data.azurerm_resource_group.selected.location
  resource_group_name     = data.azurerm_resource_group.selected.name
  dns_prefix              = "retool"
  kubernetes_version      = var.k8s_version
  private_cluster_enabled = false

  default_node_pool {
    name           = "default"
    node_count     = var.default_node_count
    tags           = {}
    vm_size        = var.default_node_size
    vnet_subnet_id = data.azurerm_subnet.selected.id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "kubenet"
    dns_service_ip = var.k8s_dns_service_ip
    service_cidr   = var.k8s_service_cidr
  }


  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "this" {
  name                  = "retool"
  enable_auto_scaling   = true
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  min_count             = 1
  max_count             = var.k8s_max_node_count
  node_labels = {
    "node.kubernetes.io/name" = "retool"
  }
  vm_size        = var.k8s_node_size
  vnet_subnet_id = data.azurerm_subnet.selected.id
}

# add the role to the identity the kubernetes cluster was assigned
resource "azurerm_role_assignment" "k8s_nc_to_rg" {
  scope                = data.azurerm_resource_group.selected.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.this.identity[0].principal_id
}
