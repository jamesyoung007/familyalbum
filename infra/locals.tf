resource "random_string" "suffix" {
  length  = 6
  lower   = true
  numeric = true
  special = false
  upper   = false
}

locals {
  name_prefix          = "${var.project_name}-${var.environment}"
  compact_name_prefix  = replace(local.name_prefix, "-", "")
  resource_group_name  = "rg-${local.name_prefix}"
  app_service_plan     = "asp-${local.name_prefix}"
  web_app_name         = "app-${local.name_prefix}-${random_string.suffix.result}"
  photo_storage_name   = substr("st${local.compact_name_prefix}${random_string.suffix.result}", 0, 24)
  photo_container_name = "family-photos"
  app_url              = "https://${local.web_app_name}.azurewebsites.net"

  common_tags = merge(
    {
      project     = var.project_name
      environment = var.environment
      managed-by  = "terraform"
    },
    var.tags
  )
}
