

module "resource_group" {
  source = "./modules/resource_group"
  
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

module "key_vault" {
  source = "./modules/key_vault"
  
  name                = local.keyvault_name
  resource_group_name = module.resource_group.name
  location           = var.location
  sku_name           = var.keyvault_sku
  tags               = local.common_tags
}

module "container_registry" {
  source = "./modules/container_registry"
  
  name                = local.acr_name
  resource_group_name = module.resource_group.name
  location           = var.location
  sku                = var.acr_sku
  tags               = local.common_tags
}

module "web_app" {
  source = "./modules/web_app"
  
  name                = local.webapp_name
  resource_group_name = module.resource_group.name
  location           = var.location
  sku_name           = var.webapp_sku
  tags               = local.common_tags
}

module "kubernetes_cluster" {
  source = "./modules/kubernetes_cluster"
  
  name                = local.aks_name
  resource_group_name = module.resource_group.name
  location           = var.location
  node_count         = var.aks_node_count
  node_size          = var.aks_node_size
  tags               = local.common_tags
}
