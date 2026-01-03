# Secrets Management

This guide covers best practices for managing secrets in GCP using Secret Manager.

## Overview

Google Secret Manager provides:

- Encrypted storage at rest
- Version management
- Access control via IAM
- Automatic rotation (optional)
- Integration with Cloud Run

## Principles

1. **Never commit secrets** to version control
2. **Use Secret Manager** for all sensitive data
3. **Least privilege** - grant access only when needed
4. **Version secrets** - use version numbers or `latest`
5. **Rotate regularly** - update secrets periodically

## Creating Secrets

### Using gcloud CLI

```bash
# Create a secret
echo -n "your-secret-value" | gcloud secrets create database-url \
  --data-file=-

# Create from file
gcloud secrets create api-key \
  --data-file=./api-key.txt

# Create with replication policy (multi-region)
gcloud secrets create jwt-secret \
  --replication-policy="automatic" \
  --data-file=-
```

### Using Terraform

```hcl
resource "google_secret_manager_secret" "database_url" {
  secret_id = "database-url"

  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "database_url" {
  secret      = google_secret_manager_secret.database_url.id
  secret_data = "your-secret-value"
}
```

## Common Secrets

### Backend Secrets

| Secret Name            | Description                            | Example                          |
| ---------------------- | -------------------------------------- | -------------------------------- |
| `database-url`         | Database connection string             | `postgresql://user:pass@host/db` |
| `direct-url`           | Direct database URL (bypasses pooling) | `postgresql://user:pass@host/db` |
| `jwt-secret`           | JWT signing secret                     | `your-random-secret-key`         |
| `api-key`              | Third-party API key                    | `sk_live_...`                    |
| `smtp-password`        | Email service password                 | `your-smtp-password`             |
| `firebase-credentials` | Firebase service account JSON (base64) | Base64 encoded JSON              |

### Frontend Secrets

**Note**: Frontend secrets are typically public (build-time env vars). Use Secret Manager only for truly sensitive frontend secrets (rare).

## Accessing Secrets

### From Cloud Run

Secrets are injected as environment variables:

```bash
# Deploy with secrets
gcloud run deploy my-service \
  --update-secrets="DATABASE_URL=database-url:latest,API_KEY=api-key:latest"
```

In your application code:

```typescript
// Secrets are available as environment variables
const dbUrl = process.env.DATABASE_URL;
const apiKey = process.env.API_KEY;
```

### From Application Code (Direct Access)

If you need to access Secret Manager directly:

```typescript
import { SecretManagerServiceClient } from "@google-cloud/secret-manager";

const client = new SecretManagerServiceClient();

async function getSecret(secretName: string): Promise<string> {
  const [version] = await client.accessSecretVersion({
    name: `projects/${PROJECT_ID}/secrets/${secretName}/versions/latest`,
  });

  return version.payload?.data?.toString() || "";
}
```

## Secret Versions

### Using Latest Version

```bash
# Always get the latest version
--update-secrets="DATABASE_URL=database-url:latest"
```

### Using Specific Version

```bash
# Use specific version number
--update-secrets="DATABASE_URL=database-url:1"
```

### Creating New Versions

```bash
# Add new version
echo -n "new-secret-value" | gcloud secrets versions add database-url \
  --data-file=-

# List versions
gcloud secrets versions list database-url

# Access specific version
gcloud secrets versions access 2 --secret=database-url
```

## Environment-Specific Secrets

### Naming Convention

Use environment suffixes:

- `database-url-dev`
- `database-url-staging`
- `database-url-prod`

### Creating Environment Secrets

```bash
# Development
echo -n "dev-db-url" | gcloud secrets create database-url-dev --data-file=-

# Staging
echo -n "staging-db-url" | gcloud secrets create database-url-staging --data-file=-

# Production
echo -n "prod-db-url" | gcloud secrets create database-url-prod --data-file=-
```

### Using in Cloud Run

```bash
# Development deployment
gcloud run deploy backend-dev \
  --update-secrets="DATABASE_URL=database-url-dev:latest"

# Production deployment
gcloud run deploy backend-prod \
  --update-secrets="DATABASE_URL=database-url-prod:latest"
```

## IAM Permissions

### Grant Access to Service Account

```bash
# Grant Secret Manager access to Cloud Run service account
gcloud secrets add-iam-policy-binding database-url \
  --member="serviceAccount:cloud-run-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

### Grant Access to User

```bash
# Grant access to specific user
gcloud secrets add-iam-policy-binding database-url \
  --member="user:developer@example.com" \
  --role="roles/secretmanager.secretAccessor"
```

## Secret Rotation

### Manual Rotation

```bash
# 1. Create new version
echo -n "new-secret-value" | gcloud secrets versions add database-url --data-file=-

# 2. Update Cloud Run to use new version
gcloud run services update backend \
  --update-secrets="DATABASE_URL=database-url:2"

# 3. Test the new secret

# 4. If successful, update to latest
gcloud run services update backend \
  --update-secrets="DATABASE_URL=database-url:latest"
```

### Automatic Rotation (Advanced)

Set up automatic rotation using Cloud Functions or Cloud Scheduler:

```bash
# Create rotation function (example)
gcloud functions deploy rotate-secret \
  --runtime nodejs20 \
  --trigger-http \
  --entry-point rotateSecret
```

## Best Practices

### 1. Secret Naming

- Use lowercase with hyphens: `database-url`, `api-key`
- Include environment: `database-url-prod`
- Be descriptive: `stripe-secret-key` not `key1`

### 2. Secret Organization

```
secrets/
├── database/
│   ├── database-url-dev
│   ├── database-url-staging
│   └── database-url-prod
├── api-keys/
│   ├── stripe-secret-key
│   └── sendgrid-api-key
└── auth/
    ├── jwt-secret
    └── oauth-client-secret
```

### 3. Access Control

- Grant access only to service accounts that need it
- Use least privilege principle
- Regularly audit IAM bindings

### 4. Version Management

- Use `latest` for automatic updates
- Use version numbers for controlled rollouts
- Keep old versions for rollback capability

### 5. Monitoring

- Set up alerts for secret access failures
- Monitor secret access logs
- Track secret rotation events

## Security Checklist

- [ ] All secrets stored in Secret Manager
- [ ] No secrets in code or configuration files
- [ ] Service accounts have least privilege access
- [ ] Secrets are versioned
- [ ] Rotation process documented
- [ ] Access logs monitored
- [ ] Environment-specific secrets separated
- [ ] Backup strategy for critical secrets

## Common Patterns

### Pattern 1: Database Connection

```bash
# Create secret
echo -n "postgresql://user:pass@host/db" | \
  gcloud secrets create database-url --data-file=-

# Use in Cloud Run
gcloud run deploy backend \
  --update-secrets="DATABASE_URL=database-url:latest"
```

### Pattern 2: API Keys

```bash
# Create secret
echo -n "sk_live_..." | \
  gcloud secrets create stripe-secret-key --data-file=-

# Use in Cloud Run
gcloud run deploy backend \
  --update-secrets="STRIPE_SECRET_KEY=stripe-secret-key:latest"
```

### Pattern 3: JSON Credentials (Base64)

```bash
# Encode JSON file
cat service-account.json | base64 | \
  gcloud secrets create firebase-credentials --data-file=-

# Use in Cloud Run
gcloud run deploy backend \
  --update-secrets="FIREBASE_CREDENTIALS_BASE64=firebase-credentials:latest"
```

## Troubleshooting

### Issue: "Permission denied" accessing secret

**Solution**:

1. Verify service account has `roles/secretmanager.secretAccessor`
2. Check IAM bindings: `gcloud secrets get-iam-policy secret-name`
3. Ensure secret exists: `gcloud secrets list`

### Issue: "Secret not found"

**Solution**:

1. Verify secret name matches exactly (case-sensitive)
2. Check secret exists: `gcloud secrets describe secret-name`
3. Ensure you're in the correct project

### Issue: "Invalid secret version"

**Solution**:

1. List versions: `gcloud secrets versions list secret-name`
2. Use valid version number or `latest`
3. Ensure version exists

## Additional Resources

- [Secret Manager Documentation](https://cloud.google.com/secret-manager/docs)
- [Secret Manager Best Practices](https://cloud.google.com/secret-manager/docs/best-practices)
- [Secret Manager IAM](https://cloud.google.com/secret-manager/docs/access-control)
