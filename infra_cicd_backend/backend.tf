terraform {
  backend "local" {
    path = "dev.tfstate"
  }
}

# Alternative configuration for prod:
# terraform {
#   backend "local" {
#     path = "prod.tfstate"
#   }
# }

# Note: To switch between environments, either:
# 1. Change the path value and run: terraform init -reconfigure
# 2. Use Terraform workspaces (recommended for local backend)
