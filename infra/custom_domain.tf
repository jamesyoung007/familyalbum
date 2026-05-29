locals {
  custom_domain_url = var.custom_domain_enabled ? "https://${var.custom_domain_hostname}" : null
}

resource "cloudflare_dns_record" "app_cname" {
  count = var.custom_domain_enabled ? 1 : 0

  zone_id = var.cloudflare_zone_id
  name    = var.custom_domain_hostname
  type    = "CNAME"
  content = module.web_app.default_hostname
  proxied = false
  ttl     = 1
  comment = "Managed by Terraform for ${local.name_prefix} Azure App Service."
}

resource "cloudflare_dns_record" "app_txt_validation" {
  count = var.custom_domain_enabled ? 1 : 0

  zone_id = var.cloudflare_zone_id
  name    = "asuid.${var.custom_domain_hostname}"
  type    = "TXT"
  content = module.web_app.custom_domain_verification_id
  proxied = false
  ttl     = 1
  comment = "Managed by Terraform for Azure App Service custom domain validation."
}

resource "azurerm_app_service_custom_hostname_binding" "app" {
  count = var.custom_domain_enabled ? 1 : 0

  hostname            = var.custom_domain_hostname
  app_service_name    = module.web_app.name
  resource_group_name = azurerm_resource_group.main.name

  depends_on = [
    cloudflare_dns_record.app_cname,
    cloudflare_dns_record.app_txt_validation
  ]
}

resource "azurerm_app_service_managed_certificate" "app" {
  count = var.custom_domain_enabled ? 1 : 0

  custom_hostname_binding_id = azurerm_app_service_custom_hostname_binding.app[0].id
}

resource "azurerm_app_service_certificate_binding" "app" {
  count = var.custom_domain_enabled ? 1 : 0

  hostname_binding_id = azurerm_app_service_custom_hostname_binding.app[0].id
  certificate_id      = azurerm_app_service_managed_certificate.app[0].id
  ssl_state           = "SniEnabled"
}
