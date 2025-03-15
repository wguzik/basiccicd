variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "westeurope"
}

variable "keyvault_sku" {
  description = "SKU name for Key Vault"
  type        = string
  default     = "basic"
}

variable "acr_sku" {
  description = "SKU for Azure Container Registry"
  type        = string
  default     = "Standard"
}

variable "webapp_sku" {
  description = "SKU for Web App"
  type        = string
  default     = "P0v3"
}

variable "aks_node_count" {
  description = "Number of nodes in AKS cluster"
  type        = number
  default     = 2
}

variable "aks_node_size" {
  description = "Size of the AKS nodes"
  type        = string
  default     = "Standard_DS2_v2"
}

variable "nginx_ingress_version" {
  description = "Version of the NGINX Ingress Controller Helm chart"
  type        = string
  default     = "4.12.0"
}
