resource "azurerm_service_plan" "main" {
  name                = var.service_plan_name
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = var.service_plan_sku_name
  tags                = var.tags
}

resource "azurerm_linux_web_app" "main" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.main.id
  https_only          = true
  tags                = var.tags

  identity {
    type = "SystemAssigned"
  }

  site_config {
    app_command_line       = "node server.js"
    always_on              = var.service_plan_sku_name == "F1" ? false : true
    ftps_state             = "Disabled"
    minimum_tls_version    = "1.2"
    use_32_bit_worker      = false
    vnet_route_all_enabled = false

    application_stack {
      node_version = "22-lts"
    }
  }

  app_settings = {
    NEXTAUTH_URL                    = var.app_url
    NEXTAUTH_SECRET                 = var.nextauth_secret
    GOOGLE_CLIENT_ID                = var.google_client_id
    GOOGLE_CLIENT_SECRET            = var.google_client_secret
    ALLOWED_EMAILS                  = join(",", var.allowed_emails)
    AZURE_STORAGE_CONNECTION_STRING = var.storage_connection_string
    AZURE_STORAGE_CONTAINER         = var.storage_container_name
    SCM_DO_BUILD_DURING_DEPLOYMENT  = "false"
    WEBSITE_NODE_DEFAULT_VERSION    = "~22"
  }

  logs {
    application_logs {
      file_system_level = "Information"
    }

    http_logs {
      file_system {
        retention_in_days = 7
        retention_in_mb   = 35
      }
    }
  }
}
