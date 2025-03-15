output "id" {
  value = azurerm_kubernetes_cluster.this.id
}

output "name" {
  value = azurerm_kubernetes_cluster.this.name
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive = true
} 

output "aks_login_command" {
  value = "az aks get-credentials --name ${azurerm_kubernetes_cluster.this.name} --resource-group ${var.resource_group_name}"
}
