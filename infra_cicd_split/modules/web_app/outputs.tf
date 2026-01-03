output "app_service_plan_id" {
  description = "The ID of the App Service Plan"
  value       = azurerm_service_plan.this.id
}

output "app_service_plan_name" {
  description = "The name of the App Service Plan"
  value       = azurerm_service_plan.this.name
}

output "web_app_id" {
  description = "The ID of the Web App"
  value       = azurerm_linux_web_app.this.id
}

output "web_app_name" {
  description = "The name of the Web App"
  value       = azurerm_linux_web_app.this.name
}

output "web_app_default_hostname" {
  description = "The default hostname of the Web App"
  value       = azurerm_linux_web_app.this.default_hostname
}

output "web_app_url" {
  description = "The URL of the Web App"
  value       = "https://${azurerm_linux_web_app.this.default_hostname}"
}
