# Quick Reference Guide

A quick reference for common GCP deployment tasks.

## 🚀 Quick Start Commands

### Initial Setup

```bash
# 1. Create GCP project
gcloud projects create your-project-id --name="Your Project"

# 2. Enable APIs
gcloud services enable cloudbuild.googleapis.com run.googleapis.com artifactregistry.googleapis.com secretmanager.googleapis.com

# 3. Create service accounts (see setup/02-iam-setup.md)

# 4. Create Artifact Registry
gcloud artifacts repositories create docker-repo --repository-format=docker --location=us-central1

# 5. Deploy infrastructure with Terraform
cd terraform
terraform init
terraform apply -var-file=environments/dev.tfvars
```

### Daily Operations

```bash
# Deploy backend manually
gcloud builds submit --config=cloudbuild.backend.yaml \
  --substitutions="_SERVICE_NAME=backend,_REGION=us-central1,_ENV=prod"

# Deploy frontend manually
gcloud builds submit --config=cloudbuild.frontend.yaml \
  --substitutions="_SERVICE_NAME=frontend,_REGION=us-central1,_ENV=prod"

# View Cloud Run logs
gcloud run services logs read backend --region=us-central1 --limit=50

# Update environment variables
gcloud run services update backend --region=us-central1 \
  --update-env-vars="NODE_ENV=production,LOG_LEVEL=debug"

# Update secrets
gcloud run services update backend --region=us-central1 \
  --update-secrets="DATABASE_URL=database-url:latest"
```

## 📋 Common Tasks

### Create a Secret

```bash
echo -n "secret-value" | gcloud secrets create secret-name --data-file=-
```

### Update a Secret

```bash
echo -n "new-secret-value" | gcloud secrets versions add secret-name --data-file=-
```

### List Secrets

```bash
gcloud secrets list
```

### Get Service URL

```bash
gcloud run services describe service-name --region=us-central1 --format="value(status.url)"
```

### Scale Service

```bash
gcloud run services update service-name --region=us-central1 \
  --min-instances=1 --max-instances=10
```

### View Service Logs

```bash
# Recent logs
gcloud run services logs read service-name --region=us-central1

# Stream logs
gcloud run services logs tail service-name --region=us-central1

# Filter by severity
gcloud logging read "resource.type=cloud_run_revision AND severity>=ERROR" --limit=50
```

## 🔧 Troubleshooting

### Service Won't Start

```bash
# Check logs
gcloud run services logs read service-name --region=us-central1 --limit=100

# Check service status
gcloud run services describe service-name --region=us-central1

# Check IAM permissions
gcloud projects get-iam-policy PROJECT_ID
```

### Build Fails

```bash
# Check build logs
gcloud builds list --limit=5
gcloud builds log BUILD_ID

# Check Cloud Build permissions
gcloud projects get-iam-policy PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:*cloudbuild*"
```

### Secret Not Accessible

```bash
# Check secret exists
gcloud secrets describe secret-name

# Check IAM permissions
gcloud secrets get-iam-policy secret-name

# Grant access
gcloud secrets add-iam-policy-binding secret-name \
  --member="serviceAccount:cloud-run-sa@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

## 📊 Monitoring

### View Metrics

```bash
# Cloud Run metrics
gcloud monitoring time-series list \
  --filter='resource.type="cloud_run_revision"'

# Error rate
gcloud monitoring time-series list \
  --filter='metric.type="run.googleapis.com/request_count" AND metric.label.response_code_class="5xx"'
```

### Set Up Alerts

```bash
# Create alert policy (see setup/09-connecting-services.md)
gcloud alpha monitoring policies create --notification-channels=CHANNEL_ID \
  --display-name="High Error Rate" \
  --condition-threshold-value=10
```

## 🔐 Security

### Verify IAM Permissions

```bash
# List all IAM bindings
gcloud projects get-iam-policy PROJECT_ID

# Check service account permissions
gcloud projects get-iam-policy PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:SERVICE_ACCOUNT_EMAIL"
```

### Rotate Secrets

```bash
# 1. Create new version
echo -n "new-secret" | gcloud secrets versions add secret-name --data-file=-

# 2. Update Cloud Run to use new version
gcloud run services update service-name --region=us-central1 \
  --update-secrets="ENV_VAR=secret-name:2"

# 3. Test

# 4. Update to latest
gcloud run services update service-name --region=us-central1 \
  --update-secrets="ENV_VAR=secret-name:latest"
```

## 📚 Documentation Links

- [Architecture](./architecture.md) - System architecture
- [Setup Guides](./setup/) - Step-by-step setup instructions
- [CI/CD](./cicd/README.md) - Cloud Build templates
- [Terraform](./terraform/README.md) - Infrastructure as Code
- [Secrets](./secrets/README.md) - Secrets management

## 🆘 Getting Help

1. Check the relevant setup guide in `setup/`
2. Review troubleshooting sections in each guide
3. Check GCP documentation links in each guide
4. Review Cloud Run logs for application errors
5. Check Cloud Build logs for deployment errors

---

**Last Updated**: 2024
