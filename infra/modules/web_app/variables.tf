variable "name" {
  type        = string
  description = "Azure App Service name."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "service_plan_name" {
  type        = string
  description = "App Service Plan name."
}

variable "service_plan_sku_name" {
  type        = string
  description = "App Service Plan SKU."
}

variable "app_url" {
  type        = string
  description = "Public web app URL."
}

variable "google_client_id" {
  type        = string
  sensitive   = true
  description = "Google OAuth client ID."
}

variable "google_client_secret" {
  type        = string
  sensitive   = true
  description = "Google OAuth client secret."
}

variable "nextauth_secret" {
  type        = string
  sensitive   = true
  description = "NextAuth secret."
}

variable "allowed_emails" {
  type        = list(string)
  sensitive   = true
  description = "Allowed Gmail addresses."
}

variable "storage_connection_string" {
  type        = string
  sensitive   = true
  description = "Azure Storage connection string."
}

variable "storage_container_name" {
  type        = string
  description = "Photo blob container name."
}

variable "tags" {
  type        = map(string)
  description = "Azure tags."
}
