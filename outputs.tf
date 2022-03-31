output "hostname" {
  value = data.azurerm_dns_zone.main.name
}

output "tenants" {
  value = [for tenant in var.tenants : tenant]
}

output "public_ip_address" {
  value = azurerm_public_ip.main.ip_address
}
