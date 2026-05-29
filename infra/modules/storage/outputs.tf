output "storage_account_name" {
  value = azurerm_storage_account.photos.name
}

output "container_name" {
  value = azurerm_storage_container.photos.name
}

output "primary_connection_string" {
  value     = azurerm_storage_account.photos.primary_connection_string
  sensitive = true
}
