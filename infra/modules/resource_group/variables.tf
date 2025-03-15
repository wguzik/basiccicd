variable "name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region where the resource group will be created"
  type        = string
}

variable "tags" {
  description = "Tags to be applied to the resource group"
  type        = map(string)
  default     = {}
} 