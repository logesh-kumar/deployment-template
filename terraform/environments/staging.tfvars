# Staging Environment Configuration
# Usage: terraform apply -var-file=environments/staging.tfvars

project_id  = "your-project-id-staging"
region      = "us-central1"
environment = "staging"

# Service Names
frontend_service_name = "frontend"
backend_service_name  = "backend"

# Frontend Configuration (Production-like for staging)
frontend_cpu          = "1"
frontend_memory       = "1Gi"
frontend_min_instances = 1
frontend_max_instances = 20
frontend_timeout      = "60"

# Backend Configuration (Production-like for staging)
backend_cpu          = "2"
backend_memory       = "2Gi"
backend_min_instances = 1
backend_max_instances = 20
backend_timeout      = "300"

# Secrets (Update with your actual secret names)
backend_secrets = {
  # DATABASE_URL = {
  #   secret_name = "database-url-staging"
  #   version     = "latest"
  # }
  # API_KEY = {
  #   secret_name = "api-key-staging"
  #   version     = "latest"
  # }
}

# Domains (Optional)
frontend_domain = "staging.example.com"
backend_domain  = "api-staging.example.com"

# GitHub (Optional)
github_owner = ""
github_repo  = ""

# Tags
tags = {
  Environment = "staging"
  ManagedBy   = "terraform"
}

