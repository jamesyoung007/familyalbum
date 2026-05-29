variable "project_name" {
  description = "Short project name used in resource names."
  type        = string
  default     = "familyalbum"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,24}$", var.project_name))
    error_message = "project_name must be 3-24 chars using lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "prod"

  validation {
    condition     = can(regex("^[a-z0-9-]{2,12}$", var.environment))
    error_message = "environment must be 2-12 chars using lowercase letters, numbers, and hyphens."
  }
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "australiaeast"
}

variable "app_service_sku_name" {
  description = "Linux App Service Plan SKU. B1 is a practical low-cost starting point."
  type        = string
  default     = "B1"
}

variable "google_client_id" {
  description = "Google OAuth web application client ID."
  type        = string
  sensitive   = true
}

variable "google_client_secret" {
  description = "Google OAuth web application client secret."
  type        = string
  sensitive   = true
}

variable "nextauth_secret" {
  description = "Random secret used by NextAuth."
  type        = string
  sensitive   = true
}

variable "allowed_emails" {
  description = "Gmail addresses allowed to sign in."
  type        = list(string)
  sensitive   = true

  validation {
    condition     = length(var.allowed_emails) > 0
    error_message = "At least one allowed email is required."
  }
}

variable "tags" {
  description = "Common Azure tags."
  type        = map(string)
  default     = {}
}
