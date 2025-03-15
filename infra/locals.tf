locals {
  # Resource naming convention
  resource_group_name     = "${var.project_name}-${var.environment}-rg"
  vnet_name              = "${var.project_name}-${var.environment}-vnet"
  acr_name               = "${var.project_name}${var.environment}acr"
  keyvault_name          = "${var.project_name}-${var.environment}-kv"
  webapp_name            = "${var.project_name}-${var.environment}-webapp"
  aks_name               = "${var.project_name}-${var.environment}-aks"
  dns_zone_name          = "${var.project_name}-${var.environment}.local"

  # Common tags
  common_tags = {
    Environment = var.environment
    Owner       = var.owner
    Project     = var.project_name
  }
}