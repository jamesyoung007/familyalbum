variable "name" {
  type        = string
  description = "Globally unique storage account name."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "container_name" {
  type        = string
  description = "Private photo container name."
}

variable "tags" {
  type        = map(string)
  description = "Azure tags."
}
