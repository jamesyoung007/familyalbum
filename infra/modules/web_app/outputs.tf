output "name" {
  value = azurerm_linux_web_app.main.name
}

output "url" {
  value = "https://${azurerm_linux_web_app.main.default_hostname}"
}

output "default_hostname" {
  value = azurerm_linux_web_app.main.default_hostname
}

output "custom_domain_verification_id" {
  value = azurerm_linux_web_app.main.custom_domain_verification_id
}

output "principal_id" {
  value = azurerm_linux_web_app.main.identity[0].principal_id
}
