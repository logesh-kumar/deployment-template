# Development Environment Configuration
# Usage: terraform apply -var-file=environments/dev.tfvars

project_id  = "your-project-id-dev"
region      = "us-central1"
environment = "dev"

# Service Names
frontend_service_name = "frontend"
backend_service_name  = "backend"

# Frontend Configuration (Lower resources for dev)
frontend_cpu         = "1"
frontend_memory       = "512Mi"
frontend_min_instances = 0
frontend_max_instances = 5
frontend_timeout      = "60"

# Backend Configuration (Lower resources for dev)
backend_cpu          = "1"
backend_memory       = "1Gi"
backend_min_instances = 0
backend_max_instances = 5
backend_timeout      = "300"

# Secrets (Update with your actual secret names)
backend_secrets = {
  # DATABASE_URL = {
  #   secret_name = "database-url-dev"
  #   version     = "latest"
  # }
  # API_KEY = {
  #   secret_name = "api-key-dev"
  #   version     = "latest"
  # }
}

# Domains (Optional - leave empty if not using custom domains)
frontend_domain = ""
backend_domain  = ""

# GitHub (Optional - for Cloud Build triggers)
github_owner = ""
github_repo  = ""

# Tags
tags = {
  Environment = "dev"
  ManagedBy   = "terraform"
}

