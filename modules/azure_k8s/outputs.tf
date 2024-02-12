output "application_gateway" {
  value       = one(azurerm_application_gateway.this[*].name)
  description = "Application gateway name"
}

output "ag_subnet_name" {
  value       = one(azurerm_subnet.app_gw[*].id)
  description = "Application gateway subnet name"
}

output "cluster_name" {
  value       = azurerm_kubernetes_cluster.this.name
  description = "Retool k8s cluster name"
}

output "psql_fqdn" {
  value       = azurerm_postgresql_flexible_server.this.fqdn
  description = "Retool psql flex server fqdn"
}

output "psql_password" {
  value       = random_password.psql_password.result
  description = "Retool psql password"
  sensitive   = true
}

output "psql_user" {
  value       = var.psql_user
  description = "Retool psql user"
}

output "temporal_fqdn" {
  value       = one(azurerm_postgresql_flexible_server.temporal[*].fqdn)
  description = "Retool temporal psql flex server fqdn"
}

output "temporal_password" {
  value       = random_password.temporal_password.result
  description = "Temporal psql password"
  sensitive   = true
}

output "temporal_user" {
  value       = var.temporal_user
  description = "Temporal psql user"
}