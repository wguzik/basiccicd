variable "name" {
  description = "Name of the Web App"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region where the Web App will be created"
  type        = string
}

variable "sku_name" {
  description = "SKU name for the App Service Plan"
  type        = string
}

variable "tags" {
  description = "Tags to be applied to the Web App"
  type        = map(string)
  default     = {}
} 