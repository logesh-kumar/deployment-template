# Main Terraform configuration for GCP deployment
# This file provisions all infrastructure resources

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  # Optional: Configure backend for state management
  # backend "gcs" {
  #   bucket = "your-terraform-state-bucket"
  #   prefix = "terraform/state"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable required APIs
# Note: DNS API removed - it's optional and requires billing
# Error Reporting API removed - it's deprecated
resource "google_project_service" "required_apis" {
  for_each = toset([
    "cloudbuild.googleapis.com",
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "secretmanager.googleapis.com",
    "storage.googleapis.com",
    "aiplatform.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "cloudtrace.googleapis.com",
  ])

  service = each.value
  project = var.project_id

  disable_on_destroy = false
}

# Service Accounts
resource "google_service_account" "cloud_build_sa" {
  account_id   = "cloud-build-sa"
  display_name = "Cloud Build Service Account"
  description  = "Service account for Cloud Build CI/CD pipeline"
}

resource "google_service_account" "cloud_run_sa" {
  account_id   = "cloud-run-sa"
  display_name = "Cloud Run Service Account"
  description  = "Service account for Cloud Run services"
}

resource "google_service_account" "app_sa" {
  account_id   = "app-sa"
  display_name = "Application Service Account"
  description  = "Service account for application access to GCP services"
}

# IAM Roles for Cloud Build
resource "google_project_iam_member" "cloud_build_run_admin" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.cloud_build_sa.email}"
}

resource "google_project_iam_member" "cloud_build_service_account_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.cloud_build_sa.email}"
}

resource "google_project_iam_member" "cloud_build_artifact_registry_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.cloud_build_sa.email}"
}

resource "google_project_iam_member" "cloud_build_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.cloud_build_sa.email}"
}

# IAM Roles for Cloud Run
resource "google_project_iam_member" "cloud_run_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

resource "google_project_iam_member" "cloud_run_storage_admin" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

resource "google_project_iam_member" "cloud_run_aiplatform_user" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# Artifact Registry Repository
resource "google_artifact_registry_repository" "docker_repo" {
  location      = var.region
  repository_id = "docker-repo"
  description   = "Docker repository for container images"
  format        = "DOCKER"
}

# Cloud Storage Buckets
resource "google_storage_bucket" "uploads" {
  name          = "${var.project_id}-uploads-${var.environment}"
  location      = var.region
  force_destroy = var.environment != "prod"

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_storage_bucket" "media" {
  name          = "${var.project_id}-media-${var.environment}"
  location      = var.region
  force_destroy = var.environment != "prod"

  uniform_bucket_level_access = true
}

resource "google_storage_bucket" "static" {
  name          = "${var.project_id}-static-${var.environment}"
  location      = var.region
  force_destroy = var.environment != "prod"

  uniform_bucket_level_access = true

  # Make publicly readable if needed
  # iam_members {
  #   role   = "roles/storage.objectViewer"
  #   member = "allUsers"
  # }
}

resource "google_storage_bucket" "backups" {
  name          = "${var.project_id}-backups-${var.environment}"
  location      = var.region
  force_destroy = false  # Never force destroy backups

  uniform_bucket_level_access = true
  storage_class              = "NEARLINE"
}

# Cloud Run Backend Service
resource "google_cloud_run_v2_service" "backend" {
  name     = "${var.backend_service_name}-${var.environment}"
  location = var.region

  template {
    service_account = google_service_account.cloud_run_sa.email

    containers {
      # Placeholder image - will be updated by Cloud Build deployment
      # Using a minimal image that exists, Cloud Build will replace this
      image = "gcr.io/cloudrun/hello"

      resources {
        limits = {
          cpu    = var.backend_cpu
          memory = var.backend_memory
        }
      }

      env {
        name  = "NODE_ENV"
        value = "production"
      }

      env {
        name  = "ENV"
        value = var.environment
      }

      # Note: PORT is automatically set by Cloud Run, don't set it manually

      # Secrets from Secret Manager
      dynamic "env" {
        for_each = var.backend_secrets
        content {
          name = env.key
          value_source {
            secret_key_ref {
              secret  = env.value.secret_name
              version = env.value.version
            }
          }
        }
      }

      ports {
        name           = "http1"
        container_port = var.backend_port
      }
    }

    scaling {
      min_instance_count = var.backend_min_instances
      max_instance_count = var.backend_max_instances
    }

    timeout = "${var.backend_timeout}s"
  }

  traffic {
    percent = 100
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  }

  depends_on = [
    google_project_service.required_apis
  ]
}

# Cloud Run Frontend Service
resource "google_cloud_run_v2_service" "frontend" {
  name     = "${var.frontend_service_name}-${var.environment}"
  location = var.region

  template {
    service_account = google_service_account.cloud_run_sa.email

    containers {
      # Placeholder image - will be updated by Cloud Build deployment
      # Using a minimal image that exists, Cloud Build will replace this
      image = "gcr.io/cloudrun/hello"

      resources {
        limits = {
          cpu    = var.frontend_cpu
          memory = var.frontend_memory
        }
      }

      env {
        name  = "NODE_ENV"
        value = "production"
      }

      env {
        name  = "ENV"
        value = var.environment
      }

      # Note: PORT is automatically set by Cloud Run, don't set it manually

      ports {
        name           = "http1"
        container_port = var.frontend_port
      }
    }

    scaling {
      min_instance_count = var.frontend_min_instances
      max_instance_count = var.frontend_max_instances
    }

    timeout = "${var.frontend_timeout}s"
  }

  traffic {
    percent = 100
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  }

  depends_on = [
    google_project_service.required_apis
  ]

  # Ignore image changes - Cloud Build will update the image
  lifecycle {
    ignore_changes = [template[0].containers[0].image]
  }
}

# IAM: Allow unauthenticated access to Cloud Run services
resource "google_cloud_run_service_iam_member" "backend_public" {
  service  = google_cloud_run_v2_service.backend.name
  location = var.region
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_service_iam_member" "frontend_public" {
  service  = google_cloud_run_v2_service.frontend.name
  location = var.region
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Cloud Build Triggers (optional - can be created manually)
# Uncomment if you want to manage triggers via Terraform
# resource "google_cloudbuild_trigger" "backend_trigger" {
#   name        = "deploy-backend-${var.environment}"
#   description = "Trigger for backend deployment"
#   filename    = "cloudbuild.backend.yaml"
#
#   github {
#     owner = var.github_owner
#     name  = var.github_repo
#     push {
#       branch = "^main$"
#     }
#   }
#
#   substitutions = {
#     _SERVICE_NAME = var.backend_service_name
#     _REGION       = var.region
#     _ENV          = var.environment
#   }
# }

# Domain Mappings (optional - requires DNS setup)
# Uncomment and configure if you have custom domains
# resource "google_cloud_run_domain_mapping" "frontend_domain" {
#   location = var.region
#   name     = var.frontend_domain
#
#   metadata {
#     namespace = var.project_id
#   }
#
#   spec {
#     route_name = google_cloud_run_v2_service.frontend.name
#   }
# }

# resource "google_cloud_run_domain_mapping" "backend_domain" {
#   location = var.region
#   name     = var.backend_domain
#
#   metadata {
#     namespace = var.project_id
#   }
#
#   spec {
#     route_name = google_cloud_run_v2_service.backend.name
#   }
# }

