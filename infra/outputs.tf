output "resource_group_name" {
  description = "Azure resource group created for the app."
  value       = azurerm_resource_group.main.name
}

output "web_app_name" {
  description = "Azure App Service name."
  value       = module.web_app.name
}

output "web_app_url" {
  description = "Public app URL."
  value       = module.web_app.url
}

output "google_oauth_redirect_uri" {
  description = "Add this URI to the Google OAuth client after the first Terraform apply."
  value       = "${module.web_app.url}/api/auth/callback/google"
}

output "photo_storage_account_name" {
  description = "Storage account used for private family photos."
  value       = module.photos.storage_account_name
}

output "photo_container_name" {
  description = "Private blob container used for family photos."
  value       = module.photos.container_name
}
