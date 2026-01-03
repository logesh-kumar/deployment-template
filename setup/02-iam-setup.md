# 02. IAM Setup

This guide configures service accounts and IAM roles for secure, least-privilege access to GCP resources.

## Overview

We'll create service accounts for:

1. **Cloud Build** - Builds and deploys services
2. **Cloud Run** - Runs application containers
3. **Application** - Accesses GCP services (GCS, Vertex AI, etc.)

## Step 1: Create Service Accounts

```bash
# Source project config (from previous step)
source .project-config

# Cloud Build service account (for CI/CD)
gcloud iam service-accounts create cloud-build-sa \
  --display-name="Cloud Build Service Account" \
  --description="Service account for Cloud Build CI/CD pipeline"

# Cloud Run service account (for running services)
gcloud iam service-accounts create cloud-run-sa \
  --display-name="Cloud Run Service Account" \
  --description="Service account for Cloud Run services"

# Application service account (for app-level GCP access)
gcloud iam service-accounts create app-sa \
  --display-name="Application Service Account" \
  --description="Service account for application access to GCP services"
```

## Step 2: Grant Cloud Build Permissions

Cloud Build needs permissions to:

- Push images to Artifact Registry
- Deploy to Cloud Run
- Access Secret Manager (to inject secrets)

```bash
# Grant Cloud Build service account necessary roles
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")

# Grant Cloud Build service account access to Cloud Run
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role="roles/run.admin"

# Grant access to Service Accounts (to impersonate Cloud Run SA)
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"

# Grant access to Artifact Registry
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"

# Grant access to Secret Manager (to read secrets during build/deploy)
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"

# Grant access to Cloud Storage (if needed for build artifacts)
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role="roles/storage.admin"
```

## Step 3: Grant Cloud Run Permissions

Cloud Run services need permissions to:

- Access Secret Manager (read secrets)
- Access Cloud Storage (read/write files)
- Access Vertex AI (AI model inference)
- Access Cloud SQL (database connections)

```bash
# Grant Secret Manager access
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:cloud-run-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"

# Grant Cloud Storage access
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:cloud-run-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/storage.objectAdmin"

# Grant Vertex AI access (if using AI features)
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:cloud-run-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/aiplatform.user"

# Grant Cloud SQL access (if using Cloud SQL)
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:cloud-run-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/cloudsql.client"
```

## Step 4: Grant Application Service Account Permissions

If your application needs direct GCP service access:

```bash
# Grant Cloud Storage access
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:app-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/storage.objectAdmin"

# Grant Vertex AI access
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:app-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/aiplatform.user"

# Grant Pub/Sub access (if using messaging)
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:app-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/pubsub.publisher"
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:app-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/pubsub.subscriber"
```

## Step 5: Configure Cloud Run Service Account

When deploying Cloud Run services, specify the service account:

```bash
# This will be used in Cloud Build deployment step
# Example (shown in cloudbuild.yaml):
# --service-account=cloud-run-sa@${PROJECT_ID}.iam.gserviceaccount.com
```

## Step 6: Create Custom IAM Roles (Optional)

For more granular permissions, create custom roles:

```bash
# Create custom role definition file
cat > custom-app-role.yaml <<EOF
title: "Custom Application Role"
description: "Custom role for application service account"
stage: "GA"
includedPermissions:
  - storage.objects.get
  - storage.objects.create
  - storage.objects.delete
  - aiplatform.endpoints.predict
  - secretmanager.secrets.get
EOF

# Create the custom role
gcloud iam roles create customAppRole \
  --project=$PROJECT_ID \
  --file=custom-app-role.yaml

# Grant custom role to service account
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:app-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="projects/${PROJECT_ID}/roles/customAppRole"
```

## Step 7: Verify Service Accounts

```bash
# List all service accounts
gcloud iam service-accounts list

# Get details of a specific service account
gcloud iam service-accounts describe cloud-run-sa@${PROJECT_ID}.iam.gserviceaccount.com

# List IAM policy bindings for project
gcloud projects get-iam-policy $PROJECT_ID
```

## Step 8: Create Service Account Keys (If Needed)

**⚠️ Warning**: Only create keys if absolutely necessary. Prefer workload identity federation or service account impersonation.

```bash
# Create key for application service account (if needed for local development)
gcloud iam service-accounts keys create app-sa-key.json \
  --iam-account=app-sa@${PROJECT_ID}.iam.gserviceaccount.com

# Set environment variable (for local use only)
export GOOGLE_APPLICATION_CREDENTIALS="./app-sa-key.json"
```

**Security Best Practice**: Never commit service account keys to version control. Add `*.json` keys to `.gitignore`.

## Service Account Summary

| Service Account                  | Purpose                  | Key Permissions                                                 |
| -------------------------------- | ------------------------ | --------------------------------------------------------------- |
| `cloudbuild.gserviceaccount.com` | CI/CD pipeline           | Cloud Run Admin, Service Account User, Artifact Registry Writer |
| `cloud-run-sa`                   | Cloud Run services       | Secret Manager Reader, Storage Admin, Vertex AI User            |
| `app-sa`                         | Application-level access | Storage Admin, Vertex AI User, Pub/Sub Publisher                |

## Verification Checklist

- [ ] Cloud Build service account has necessary permissions
- [ ] Cloud Run service account created and configured
- [ ] Application service account created (if needed)
- [ ] IAM bindings verified
- [ ] Service account keys created only if necessary
- [ ] Keys added to `.gitignore` if created

## Common Issues

### Issue: "Permission denied" during Cloud Build

**Solution**:

1. Verify Cloud Build service account has `roles/run.admin`
2. Check that service account user role is granted
3. Ensure APIs are enabled

### Issue: "Service account not found"

**Solution**:

1. Verify service account name: `gcloud iam service-accounts list`
2. Check project ID matches
3. Ensure service account was created in correct project

### Issue: "Insufficient permissions" in Cloud Run

**Solution**:

1. Verify Cloud Run service account has required roles
2. Check IAM policy bindings: `gcloud projects get-iam-policy $PROJECT_ID`
3. Ensure service account is specified in Cloud Run deployment

## Security Best Practices

1. **Least Privilege**: Grant only necessary permissions
2. **Separate Service Accounts**: Use different SAs for different purposes
3. **No Keys in Code**: Never commit service account keys
4. **Workload Identity**: Use workload identity federation when possible
5. **Regular Audits**: Review IAM policies periodically
6. **Service Account Impersonation**: Prefer impersonation over keys

## Next Steps

Once IAM is configured, proceed to:

- **[03. Artifact Registry Setup](./03-artifact-registry.md)** - Set up container image storage

## Additional Resources

- [GCP IAM Best Practices](https://cloud.google.com/iam/docs/using-iam-securely)
- [Service Accounts Documentation](https://cloud.google.com/iam/docs/service-accounts)
- [Cloud Build Permissions](https://cloud.google.com/build/docs/iam-roles-permissions)
