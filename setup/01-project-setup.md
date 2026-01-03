# 01. GCP Project Setup

This guide walks you through creating and configuring a new GCP project for your application.

## Prerequisites

- Google Cloud account with billing enabled
- `gcloud` CLI installed and authenticated
- Appropriate permissions to create projects

## Step 1: Create a New GCP Project

### Option A: Using gcloud CLI

```bash
# Set your project variables
export PROJECT_ID="your-project-id"  # Must be globally unique
export PROJECT_NAME="Your Project Name"
export BILLING_ACCOUNT_ID="your-billing-account-id"

# Create the project
gcloud projects create $PROJECT_ID --name="$PROJECT_NAME"

# Link billing account (required for Cloud Run and other services)
gcloud billing projects link $PROJECT_ID --billing-account=$BILLING_ACCOUNT_ID

# Set as default project
gcloud config set project $PROJECT_ID
```

### Option B: Using GCP Console

1. Go to [GCP Console](https://console.cloud.google.com/)
2. Click "Select a project" → "New Project"
3. Enter project name and project ID
4. Click "Create"
5. Navigate to "Billing" → "Link a billing account"

## Step 2: Enable Required APIs

Enable all APIs needed for your deployment:

```bash
# Core APIs
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable secretmanager.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable dns.googleapis.com

# Vertex AI (if using AI features)
gcloud services enable aiplatform.googleapis.com

# Cloud SQL (if using managed database)
gcloud services enable sqladmin.googleapis.com

# Monitoring and Logging
gcloud services enable logging.googleapis.com
gcloud services enable monitoring.googleapis.com
gcloud services enable cloudtrace.googleapis.com
gcloud services enable errorreporting.googleapis.com

# IAM and Resource Manager
gcloud services enable iam.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
```

**Note**: API enablement can take a few minutes. Wait for all APIs to be enabled before proceeding.

## Step 3: Verify Project Setup

```bash
# Check current project
gcloud config get-value project

# Verify billing is linked
gcloud billing projects describe $PROJECT_ID

# List enabled APIs
gcloud services list --enabled
```

## Step 4: Set Project Variables

Create a `.env` file or export variables for use in subsequent steps:

```bash
# Create project config file
cat > .project-config <<EOF
export PROJECT_ID="your-project-id"
export PROJECT_NAME="Your Project Name"
export REGION="us-central1"  # or asia-south1, europe-west1, etc.
export ZONE="${REGION}-a"
export FRONTEND_SERVICE="your-frontend-service"
export BACKEND_SERVICE="your-backend-service"
EOF

# Source the config
source .project-config
```

## Step 5: Configure gcloud Defaults

```bash
# Set default region and zone
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE

# Verify configuration
gcloud config list
```

## Step 6: Create Project Labels (Optional)

Add labels for better organization:

```bash
# Add labels to project
gcloud projects update $PROJECT_ID \
  --update-labels=environment=dev,team=engineering,managed-by=terraform
```

## Step 7: Set Up Project Organization (Optional)

If using Google Cloud Organization:

```bash
# List available organizations
gcloud organizations list

# Set organization policy (if needed)
gcloud resource-manager org-policies list --project=$PROJECT_ID
```

## Verification Checklist

- [ ] Project created successfully
- [ ] Billing account linked
- [ ] All required APIs enabled
- [ ] Default region/zone configured
- [ ] Project variables exported
- [ ] `gcloud` authenticated and configured

## Common Issues

### Issue: "Project ID already exists"

**Solution**: Choose a different project ID. Project IDs must be globally unique.

### Issue: "Billing account not found"

**Solution**:

1. Verify billing account ID: `gcloud billing accounts list`
2. Ensure you have permission to link billing accounts

### Issue: "API enablement failed"

**Solution**:

1. Check IAM permissions
2. Wait a few minutes and retry
3. Enable APIs one at a time to identify the problematic API

## Next Steps

Once your project is set up, proceed to:

- **[02. IAM Setup](./02-iam-setup.md)** - Configure service accounts and permissions

## Additional Resources

- [GCP Project Best Practices](https://cloud.google.com/resource-manager/docs/creating-managing-projects)
- [gcloud CLI Reference](https://cloud.google.com/sdk/gcloud/reference)
- [GCP Billing Setup](https://cloud.google.com/billing/docs/how-to/manage-billing-account)
