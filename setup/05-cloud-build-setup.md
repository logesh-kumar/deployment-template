# 05. Cloud Build Setup

This guide configures Cloud Build triggers for automated CI/CD pipelines.

## Overview

Cloud Build automates:

- Building Docker images
- Running tests
- Pushing to Artifact Registry
- Deploying to Cloud Run

## Step 1: Prepare Cloud Build Configuration Files

Create `cloudbuild.backend.yaml` and `cloudbuild.frontend.yaml` in your repository root (see [CI/CD Templates](../cicd/)).

## Step 2: Create Cloud Build Triggers

### Backend Trigger

```bash
# Source project config
source .project-config

# Create backend trigger
gcloud builds triggers create github \
  --name="deploy-backend" \
  --repo-name="your-repo-name" \
  --repo-owner="your-github-username" \
  --branch-pattern="^main$" \
  --build-config="cloudbuild.backend.yaml" \
  --substitutions="_SERVICE_NAME=${BACKEND_SERVICE},_REGION=${REGION}"
```

### Frontend Trigger

```bash
# Create frontend trigger
gcloud builds triggers create github \
  --name="deploy-frontend" \
  --repo-name="your-repo-name" \
  --repo-owner="your-github-username" \
  --branch-pattern="^main$" \
  --build-config="cloudbuild.frontend.yaml" \
  --substitutions="_SERVICE_NAME=${FRONTEND_SERVICE},_REGION=${REGION}"
```

## Step 3: Configure Git Repository Connection

### Option A: GitHub App (Recommended)

```bash
# Connect GitHub repository
gcloud builds triggers create github \
  --name="deploy-backend" \
  --repo-name="your-repo" \
  --repo-owner="your-org" \
  --branch-pattern="^main$" \
  --build-config="cloudbuild.backend.yaml"
```

### Option B: Manual Repository Connection

1. Go to [Cloud Build Triggers](https://console.cloud.google.com/cloud-build/triggers)
2. Click "Connect Repository"
3. Select your Git provider (GitHub, GitLab, Bitbucket)
4. Authenticate and select repository
5. Create trigger

## Step 4: Configure Branch Patterns

Set up triggers for different branches:

```bash
# Production (main branch)
gcloud builds triggers create github \
  --name="deploy-backend-prod" \
  --repo-name="your-repo" \
  --repo-owner="your-org" \
  --branch-pattern="^main$" \
  --build-config="cloudbuild.backend.yaml" \
  --substitutions="_ENV=prod"

# Staging (staging branch)
gcloud builds triggers create github \
  --name="deploy-backend-staging" \
  --repo-name="your-repo" \
  --repo-owner="your-org" \
  --branch-pattern="^staging$" \
  --build-config="cloudbuild.backend.yaml" \
  --substitutions="_ENV=staging"

# Development (dev branch)
gcloud builds triggers create github \
  --name="deploy-backend-dev" \
  --repo-name="your-repo" \
  --repo-owner="your-org" \
  --branch-pattern="^dev$" \
  --build-config="cloudbuild.backend.yaml" \
  --substitutions="_ENV=dev"
```

## Step 5: Configure Path Filters (Optional)

Only trigger builds when specific paths change:

```bash
# Backend trigger (only on backend changes)
gcloud builds triggers create github \
  --name="deploy-backend" \
  --repo-name="your-repo" \
  --repo-owner="your-org" \
  --branch-pattern="^main$" \
  --build-config="cloudbuild.backend.yaml" \
  --included-files="apps/api/**,packages/**"

# Frontend trigger (only on frontend changes)
gcloud builds triggers create github \
  --name="deploy-frontend" \
  --repo-name="your-repo" \
  --repo-owner="your-org" \
  --branch-pattern="^main$" \
  --build-config="cloudbuild.frontend.yaml" \
  --included-files="apps/web/**,packages/shared-types/**"
```

## Step 6: Set Up Manual Triggers

For on-demand deployments:

```bash
# Manual backend deployment
gcloud builds submit --config=cloudbuild.backend.yaml \
  --substitutions="_SERVICE_NAME=${BACKEND_SERVICE},_REGION=${REGION}"

# Manual frontend deployment
gcloud builds submit --config=cloudbuild.frontend.yaml \
  --substitutions="_SERVICE_NAME=${FRONTEND_SERVICE},_REGION=${REGION}"
```

## Step 7: Configure Build Substitutions

Set default substitutions for triggers:

```bash
# Update trigger with substitutions
gcloud builds triggers update deploy-backend \
  --substitutions="_SERVICE_NAME=${BACKEND_SERVICE},_REGION=${REGION},_ENV=prod"
```

## Step 8: Set Up Build Notifications (Optional)

Configure notifications for build status:

```bash
# Create Pub/Sub topic for build notifications
gcloud pubsub topics create cloud-builds

# Create subscription
gcloud pubsub subscriptions create cloud-builds-sub \
  --topic=cloud-builds

# Update trigger to send notifications
gcloud builds triggers update deploy-backend \
  --pubsub-config="topic=projects/${PROJECT_ID}/topics/cloud-builds"
```

## Step 9: Configure Build Timeouts

Set appropriate timeouts:

```bash
# In cloudbuild.yaml, set:
options:
  machineType: "E2_HIGHCPU_8"
  timeout: "1200s"  # 20 minutes
```

## Step 10: Enable Build Logs

Ensure build logs are accessible:

```bash
# View recent builds
gcloud builds list --limit=10

# View specific build logs
gcloud builds log BUILD_ID

# Stream build logs
gcloud builds log --stream
```

## Step 11: Test Build Trigger

Test the trigger by pushing to the configured branch:

```bash
# Make a small change and push
git checkout main
echo "# Test build" >> README.md
git add README.md
git commit -m "test: trigger build"
git push origin main

# Monitor build
gcloud builds list --ongoing
```

## Step 12: Configure Approval Gates (Optional)

Require manual approval for production deployments:

```bash
# This requires Cloud Build approval configuration
# See: https://cloud.google.com/build/docs/automate-builds/create-manual-triggers
```

## Step 13: Set Up Build Tags

Tag builds with metadata:

```bash
# In cloudbuild.yaml, add tags:
tags:
  - "backend"
  - "production"
  - "v1.0.0"
```

## Verification Checklist

- [ ] Backend trigger created and configured
- [ ] Frontend trigger created and configured
- [ ] Repository connected
- [ ] Branch patterns configured
- [ ] Path filters set (if needed)
- [ ] Substitutions configured
- [ ] Build tested successfully
- [ ] Logs accessible
- [ ] Notifications configured (optional)

## Common Issues

### Issue: "Trigger not firing"

**Solution**:

1. Verify branch pattern matches your branch name
2. Check repository connection status
3. Ensure Cloud Build API is enabled
4. Check included files filter (if set)

### Issue: "Permission denied"

**Solution**:

1. Verify Cloud Build service account has necessary permissions
2. Check IAM roles: `roles/cloudbuild.builds.builder`
3. Ensure service account can deploy to Cloud Run

### Issue: "Build timeout"

**Solution**:

1. Increase timeout in `cloudbuild.yaml`
2. Optimize build steps
3. Use faster machine types
4. Cache dependencies

### Issue: "Image push failed"

**Solution**:

1. Verify Artifact Registry permissions
2. Check repository exists
3. Ensure Docker authentication is configured
4. Verify image path format

## Best Practices

1. **Separate Triggers**: Use different triggers for frontend/backend
2. **Path Filters**: Only build what changed
3. **Branch Strategy**: Use branch patterns for environments
4. **Substitutions**: Parameterize build configs
5. **Timeouts**: Set appropriate timeouts
6. **Notifications**: Monitor build status
7. **Approval Gates**: Require approval for production
8. **Build Tags**: Tag builds for organization
9. **Logging**: Keep build logs for debugging
10. **Cost Optimization**: Use appropriate machine types

## Next Steps

Once Cloud Build is configured, proceed to:

- **[06. Vertex AI Setup](./06-vertex-ai-setup.md)** - Configure AI/ML services (if needed)
- **[07. GCS Setup](./07-gcs-setup.md)** - Set up Cloud Storage buckets

## Additional Resources

- [Cloud Build Documentation](https://cloud.google.com/build/docs)
- [Cloud Build Triggers](https://cloud.google.com/build/docs/triggers)
- [Build Configuration Reference](https://cloud.google.com/build/docs/build-config)
