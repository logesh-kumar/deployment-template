# Terraform variables for GCP deployment
# Customize these values per project and environment

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region for resources"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

# Service Names
variable "frontend_service_name" {
  description = "Frontend Cloud Run service name"
  type        = string
  default     = "frontend"
}

variable "backend_service_name" {
  description = "Backend Cloud Run service name"
  type        = string
  default     = "backend"
}

# Frontend Configuration
variable "frontend_cpu" {
  description = "CPU allocation for frontend service"
  type        = string
  default     = "1"
}

variable "frontend_memory" {
  description = "Memory allocation for frontend service"
  type        = string
  default     = "512Mi"
}

variable "frontend_port" {
  description = "Port for frontend service"
  type        = number
  default     = 8080
}

variable "frontend_min_instances" {
  description = "Minimum instances for frontend service"
  type        = number
  default     = 0
}

variable "frontend_max_instances" {
  description = "Maximum instances for frontend service"
  type        = number
  default     = 50
}

variable "frontend_timeout" {
  description = "Timeout for frontend service (seconds)"
  type        = string
  default     = "60"
}

# Backend Configuration
variable "backend_cpu" {
  description = "CPU allocation for backend service"
  type        = string
  default     = "1"
}

variable "backend_memory" {
  description = "Memory allocation for backend service"
  type        = string
  default     = "1Gi"
}

variable "backend_port" {
  description = "Port for backend service"
  type        = number
  default     = 8080
}

variable "backend_min_instances" {
  description = "Minimum instances for backend service"
  type        = number
  default     = 0
}

variable "backend_max_instances" {
  description = "Maximum instances for backend service"
  type        = number
  default     = 100
}

variable "backend_timeout" {
  description = "Timeout for backend service (seconds)"
  type        = string
  default     = "300"
}

# Secrets Configuration
variable "backend_secrets" {
  description = "Map of environment variable names to Secret Manager secrets for backend"
  type = map(object({
    secret_name = string
    version     = string
  }))
  default = {
    # Example:
    # DATABASE_URL = {
    #   secret_name = "database-url"
    #   version     = "latest"
    # }
  }
}

# Domain Configuration (Optional)
variable "frontend_domain" {
  description = "Custom domain for frontend (optional)"
  type        = string
  default     = ""
}

variable "backend_domain" {
  description = "Custom domain for backend (optional)"
  type        = string
  default     = ""
}

# GitHub Configuration (for Cloud Build triggers)
variable "github_owner" {
  description = "GitHub organization or username"
  type        = string
  default     = ""
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = ""
}

# Additional Tags
variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}

