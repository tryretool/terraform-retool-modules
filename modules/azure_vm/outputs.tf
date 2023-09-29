output "vm_public_ip" {
  value       = azurerm_public_ip.this.ip_address
  description = "Public IP of VM Instance"
}