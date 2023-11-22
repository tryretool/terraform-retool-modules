output "flex_subnet" {
  value = azurerm_subnet.this[0].id
  description = "Subnet id of subnet for Azure Flexible servers"
}

output "private_dns_zone_id" {
  value = azurerm_private_dns_zone.this[0].id
  description = "Id of private dns zone"
}

output "vm_public_ip" {
  value       = azurerm_public_ip.this.ip_address
  description = "Public IP of VM Instance"
}
