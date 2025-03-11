variable "name" {
  description = "Name of the Container Registry"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region where the Container Registry will be created"
  type        = string
}

variable "sku" {
  description = "SKU for the Container Registry"
  type        = string
  default     = "Standard"
}

variable "tags" {
  description = "Tags to be applied to the Container Registry"
  type        = map(string)
  default     = {}
} 