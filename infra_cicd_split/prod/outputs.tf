output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.resource_group.name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = module.resource_group.id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = module.vnet.name
}

output "vnet_id" {
  description = "ID of the virtual network"
  value       = module.vnet.id
}

output "subnet_ids" {
  description = "Map of subnet names to their IDs"
  value       = module.vnet.subnet_ids
}

output "app_service_plan_name" {
  description = "Name of the App Service Plan"
  value       = module.web_app.app_service_plan_name
}

output "web_app_name" {
  description = "Name of the Web App"
  value       = module.web_app.web_app_name
}

output "web_app_url" {
  description = "URL of the Web App"
  value       = module.web_app.web_app_url
}

output "web_app_default_hostname" {
  description = "Default hostname of the Web App"
  value       = module.web_app.web_app_default_hostname
}
