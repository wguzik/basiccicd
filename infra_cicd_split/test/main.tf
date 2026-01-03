# Random suffix for unique resource names
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

locals {
  resource_suffix = random_string.suffix.result
  
  # Common tags applied to all resources
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Owner       = var.owner
  }

  # Resource names following CAF naming convention
  resource_group_name     = "rg-${var.project_name}-${var.environment}-${local.resource_suffix}"
  vnet_name              = "vnet-${var.project_name}-${var.environment}-${local.resource_suffix}"
  app_service_plan_name  = "plan-${var.project_name}-${var.environment}-${local.resource_suffix}"
  web_app_name           = "app-${var.project_name}-${var.environment}-${local.resource_suffix}"
}

# Resource Group Module
module "resource_group" {
  source = "../modules/resource_group"

  resource_group_name = local.resource_group_name
  location            = var.location
  tags                = local.common_tags
}

# Virtual Network Module
module "vnet" {
  source = "../modules/vnet"

  vnet_name           = local.vnet_name
  resource_group_name = module.resource_group.name
  location            = var.location
  address_space       = ["10.0.0.0/16"]
  
  subnet_config = {
    subnet-app = {
      address_prefixes = ["10.0.0.0/24"]
    }
    subnet-data = {
      address_prefixes = ["10.0.1.0/24"]
    }
    subnet-integration = {
      address_prefixes = ["10.0.2.0/24"]
    }
  }

  tags = local.common_tags

  depends_on = [module.resource_group]
}

# Web App Module
module "web_app" {
  source = "../modules/web_app"

  app_service_plan_name = local.app_service_plan_name
  web_app_name          = local.web_app_name
  resource_group_name   = module.resource_group.name
  location              = var.location
  sku_name              = "B1"
  integration_subnet_id = module.vnet.integration_subnet_id
  tags                  = local.common_tags

  depends_on = [module.vnet]
}
