# Terraform Infrastructure as Code

This directory contains Terraform configurations for provisioning GCP infrastructure.

## Files

- **`main.tf`** - Main infrastructure resources
- **`variables.tf`** - Variable definitions
- **`outputs.tf`** - Output values
- **`environments/`** - Environment-specific configurations
  - `dev.tfvars` - Development environment
  - `staging.tfvars` - Staging environment
  - `prod.tfvars` - Production environment

## Prerequisites

1. **Terraform installed** (>= 1.5.0)

   ```bash
   # macOS
   brew install terraform

   # Linux
   wget https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip
   unzip terraform_1.5.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   ```

2. **GCP Authentication**

   ```bash
   gcloud auth application-default login
   ```

3. **Terraform GCP Provider**
   - Automatically downloaded on `terraform init`

## Important Notes

### Cloud Run v2 Requirements

- **Timeout format**: Timeout values must be strings with "s" suffix (e.g., `"300s"`). Terraform automatically adds the suffix.
- **PORT environment variable**: Cloud Run automatically sets PORT - do not set it manually in your configuration.
- **Placeholder images**: Services are created with placeholder images (`gcr.io/cloudrun/hello`) and updated by Cloud Build deployments.
- **Image lifecycle**: Terraform ignores image changes so Cloud Build can update images without conflicts.

### API Requirements

- **Billing**: Most APIs require billing to be enabled on your GCP project.
- **Deprecated APIs**: `errorreporting.googleapis.com` and `dns.googleapis.com` are not included (deprecated/optional).

## Quick Start

### 1. Customize Variables

Edit the production `.tfvars` file:

```bash
# Edit production environment
vim terraform/environments/prod.tfvars

# Update:
# - project_id
# - backend_secrets (with your secret names)
# - timeout values (as strings, e.g., "300" for 300 seconds)
# - domains (if using custom domains)
```

### 2. Initialize Terraform

```bash
cd terraform
terraform init
```

### 3. Plan Changes

```bash
# Production
terraform plan -var-file=environments/prod.tfvars
```

### 4. Apply Changes

```bash
# Production
terraform apply -var-file=environments/prod.tfvars
```

## What Gets Created

### Service Accounts

- `cloud-build-sa` - For Cloud Build CI/CD
- `cloud-run-sa` - For Cloud Run services
- `app-sa` - For application-level GCP access

### Artifact Registry

- Docker repository for container images

### Cloud Storage Buckets

- `{project-id}-uploads-{env}` - User uploads
- `{project-id}-media-{env}` - Media files
- `{project-id}-static-{env}` - Static assets
- `{project-id}-backups-{env}` - Backups

### Cloud Run Services

- Frontend service
- Backend service

### IAM Roles

- All necessary IAM bindings for service accounts

## Customization

### Adding Secrets

Update `backend_secrets` in your `.tfvars` file:

```hcl
backend_secrets = {
  DATABASE_URL = {
    secret_name = "database-url-prod"
    version     = "latest"
  }
  API_KEY = {
    secret_name = "api-key-prod"
    version     = "latest"
  }
}
```

**Note**: Secrets must exist in Secret Manager before applying Terraform.

### Custom Domains

Uncomment domain mapping resources in `main.tf`:

```hcl
resource "google_cloud_run_domain_mapping" "frontend_domain" {
  location = var.region
  name     = var.frontend_domain
  # ...
}
```

### Cloud Build Triggers

Uncomment trigger resources in `main.tf` if you want to manage them via Terraform:

```hcl
resource "google_cloudbuild_trigger" "backend_trigger" {
  # ...
}
```

## State Management

### Local State (Default)

Terraform stores state locally in `terraform.tfstate`. This is fine for single-user setups.

### Remote State (Recommended for Teams)

Configure GCS backend in `main.tf`:

```hcl
terraform {
  backend "gcs" {
    bucket = "your-terraform-state-bucket"
    prefix = "terraform/state"
  }
}
```

Create the bucket first:

```bash
gsutil mb gs://your-terraform-state-bucket
gsutil versioning set on gs://your-terraform-state-bucket
```

## Environment Management

### Separate Projects per Environment

**Recommended**: Use separate GCP projects for each environment:

- `your-project-dev`
- `your-project-staging`
- `your-project-prod`

Update `project_id` in each `.tfvars` file accordingly.

### Single Project with Prefixes

Alternatively, use a single project with naming prefixes:

- Services: `frontend-dev`, `backend-dev`, etc.
- Buckets: `project-uploads-dev`, `project-uploads-prod`, etc.

## Common Operations

### View Outputs

```bash
terraform output
```

### Destroy Infrastructure

```bash
# Development
terraform destroy -var-file=environments/dev.tfvars

# Production (be very careful!)
terraform destroy -var-file=environments/prod.tfvars
```

### Update Resources

```bash
# Modify variables in .tfvars file
vim environments/dev.tfvars

# Plan and apply
terraform plan -var-file=environments/dev.tfvars
terraform apply -var-file=environments/dev.tfvars
```

## Best Practices

1. **Version Control**: Commit `.tfvars` files (they contain no secrets)
2. **State Locking**: Use remote state with locking for team collaboration
3. **Review Plans**: Always review `terraform plan` before applying
4. **Separate Environments**: Use separate projects or clear naming
5. **Secrets**: Never commit secrets to Terraform files
6. **Backup State**: Regularly backup Terraform state files
7. **Documentation**: Document any customizations made
8. **Testing**: Test changes in dev before staging/prod

## Troubleshooting

### Error: "API not enabled"

**Solution**: APIs are enabled automatically by Terraform, but may take a few minutes. Wait and retry.

### Error: "Permission denied"

**Solution**:

1. Verify authentication: `gcloud auth application-default login`
2. Check IAM permissions for your user account
3. Ensure required APIs are enabled

### Error: "Resource already exists"

**Solution**:

1. Import existing resource: `terraform import <resource_type>.<name> <resource_id>`
2. Or destroy and recreate: `terraform destroy` then `terraform apply`

### Error: "Secret not found"

**Solution**:

1. Create secrets in Secret Manager first
2. Verify secret names match exactly in `backend_secrets`

## Additional Resources

- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)
- [GCP Resource Manager](https://cloud.google.com/resource-manager/docs)
