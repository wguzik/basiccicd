resource "azurerm_service_plan" "this" {
  name                = "${var.name}-plan"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type            = "Linux"
  sku_name           = var.sku_name
  tags               = var.tags
}

resource "azurerm_linux_web_app" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.this.id

  site_config {
    always_on = true
    
    application_stack {
      docker_image_name = "nginx:latest"
    }
    
    container_registry_use_managed_identity = false
  }

  tags = var.tags
}