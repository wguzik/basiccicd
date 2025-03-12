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

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "webapp_subnet_prefix" {
  description = "Address prefix for the webapp subnet"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "kubernetes_subnet_prefix" {
  description = "Address prefix for the kubernetes subnet"
  type        = list(string)
  default     = ["10.0.2.0/24"]
}

variable "keyvault_sku" {
  description = "SKU name for Key Vault"
  type        = string
  default     = "standard"
}

variable "acr_sku" {
  description = "SKU for Azure Container Registry"
  type        = string
  default     = "Standard"
}

variable "webapp_sku" {
  description = "SKU for Web App"
  type        = string
  default     = "P1v2"
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
