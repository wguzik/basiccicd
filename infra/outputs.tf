output "aks_login_command" {
  value = module.kubernetes_cluster.aks_login_command
}

output "acr_url" {
  value = module.container_registry.login_server
}

output "webapp_url" {
  value = "https://${module.web_app.default_hostname}"
}