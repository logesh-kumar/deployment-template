# Terraform outputs for GCP deployment

output "project_id" {
  description = "GCP Project ID"
  value       = var.project_id
}

output "region" {
  description = "GCP Region"
  value       = var.region
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

# Service Accounts
output "cloud_build_service_account" {
  description = "Cloud Build service account email"
  value       = google_service_account.cloud_build_sa.email
}

output "cloud_run_service_account" {
  description = "Cloud Run service account email"
  value       = google_service_account.cloud_run_sa.email
}

output "app_service_account" {
  description = "Application service account email"
  value       = google_service_account.app_sa.email
}

# Artifact Registry
output "artifact_registry_repository" {
  description = "Artifact Registry repository URL"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker_repo.repository_id}"
}

# Cloud Storage Buckets
output "uploads_bucket" {
  description = "Uploads bucket name"
  value       = google_storage_bucket.uploads.name
}

output "media_bucket" {
  description = "Media bucket name"
  value       = google_storage_bucket.media.name
}

output "static_bucket" {
  description = "Static assets bucket name"
  value       = google_storage_bucket.static.name
}

output "backups_bucket" {
  description = "Backups bucket name"
  value       = google_storage_bucket.backups.name
}

# Cloud Run Services
output "frontend_service_url" {
  description = "Frontend Cloud Run service URL"
  value       = google_cloud_run_v2_service.frontend.uri
}

output "backend_service_url" {
  description = "Backend Cloud Run service URL"
  value       = google_cloud_run_v2_service.backend.uri
}

output "frontend_service_name" {
  description = "Frontend Cloud Run service name"
  value       = google_cloud_run_v2_service.frontend.name
}

output "backend_service_name" {
  description = "Backend Cloud Run service name"
  value       = google_cloud_run_v2_service.backend.name
}

# Useful Commands
output "deploy_backend_command" {
  description = "Command to manually deploy backend"
  value       = "gcloud builds submit --config=cloudbuild.backend.yaml --substitutions=_SERVICE_NAME=${var.backend_service_name},_REGION=${var.region},_ENV=${var.environment}"
}

output "deploy_frontend_command" {
  description = "Command to manually deploy frontend"
  value       = "gcloud builds submit --config=cloudbuild.frontend.yaml --substitutions=_SERVICE_NAME=${var.frontend_service_name},_REGION=${var.region},_ENV=${var.environment}"
}

