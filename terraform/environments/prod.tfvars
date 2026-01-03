# Production Environment Configuration
# Usage: terraform apply -var-file=environments/prod.tfvars
# WARNING: Review all settings carefully before applying to production!

project_id  = "your-project-id-prod"
region      = "us-central1"
environment = "prod"

# Service Names
frontend_service_name = "frontend"
backend_service_name  = "backend"

# Frontend Configuration (Production settings)
frontend_cpu          = "2"
frontend_memory       = "1Gi"
frontend_min_instances = 1  # Always available in prod
frontend_max_instances = 50
frontend_timeout      = "60"

# Backend Configuration (Production settings)
backend_cpu          = "2"
backend_memory       = "2Gi"
backend_min_instances = 1  # Always available in prod
backend_max_instances = 100
backend_timeout      = "300"

# Secrets (Update with your actual secret names)
backend_secrets = {
  # DATABASE_URL = {
  #   secret_name = "database-url-prod"
  #   version     = "latest"
  # }
  # API_KEY = {
  #   secret_name = "api-key-prod"
  #   version     = "latest"
  # }
  # JWT_SECRET = {
  #   secret_name = "jwt-secret-prod"
  #   version     = "latest"
  # }
}

# Domains (Production domains)
frontend_domain = "app.example.com"
backend_domain  = "api.example.com"

# GitHub (Optional)
github_owner = "your-org"
github_repo  = "your-repo"

# Tags
tags = {
  Environment = "prod"
  ManagedBy   = "terraform"
  Critical    = "true"
}

