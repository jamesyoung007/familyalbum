resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

module "photos" {
  source = "./modules/storage"

  name                = local.photo_storage_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  container_name      = local.photo_container_name
  tags                = local.common_tags
}

module "web_app" {
  source = "./modules/web_app"

  name                      = local.web_app_name
  resource_group_name       = azurerm_resource_group.main.name
  location                  = azurerm_resource_group.main.location
  service_plan_name         = local.app_service_plan
  service_plan_sku_name     = var.app_service_sku_name
  app_url                   = local.app_url
  google_client_id          = var.google_client_id
  google_client_secret      = var.google_client_secret
  nextauth_secret           = var.nextauth_secret
  allowed_emails            = var.allowed_emails
  storage_connection_string = module.photos.primary_connection_string
  storage_container_name    = module.photos.container_name
  tags                      = local.common_tags
}
