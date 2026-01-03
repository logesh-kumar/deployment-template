# 03. Artifact Registry Setup

This guide sets up Artifact Registry for storing Docker container images used by Cloud Run.

## Overview

Artifact Registry provides:

- Private Docker image storage
- Version management and tagging
- Integration with Cloud Build and Cloud Run
- Access control via IAM

## Step 1: Create Artifact Registry Repository

```bash
# Source project config
source .project-config

# Create Docker repository
gcloud artifacts repositories create docker-repo \
  --repository-format=docker \
  --location=$REGION \
  --description="Docker repository for container images"

# Verify repository creation
gcloud artifacts repositories list --location=$REGION
```

## Step 2: Configure Docker Authentication

Configure Docker to authenticate with Artifact Registry:

```bash
# Configure Docker authentication
gcloud auth configure-docker ${REGION}-docker.pkg.dev

# Verify authentication
gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin ${REGION}-docker.pkg.dev
```

## Step 3: Test Image Push (Optional)

Test pushing an image to verify setup:

```bash
# Pull a test image
docker pull hello-world

# Tag for Artifact Registry
docker tag hello-world ${REGION}-docker.pkg.dev/${PROJECT_ID}/docker-repo/hello-world:test

# Push to Artifact Registry
docker push ${REGION}-docker.pkg.dev/${PROJECT_ID}/docker-repo/hello-world:test

# Verify image exists
gcloud artifacts docker images list ${REGION}-docker.pkg.dev/${PROJECT_ID}/docker-repo
```

## Step 4: Configure Repository Permissions

Set up IAM permissions for the repository:

```bash
# Grant Cloud Build service account write access
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")

gcloud artifacts repositories add-iam-policy-binding docker-repo \
  --location=$REGION \
  --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"

# Grant Cloud Run service account read access (if needed)
gcloud artifacts repositories add-iam-policy-binding docker-repo \
  --location=$REGION \
  --member="serviceAccount:cloud-run-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.reader"
```

## Step 5: Create Multiple Repositories (Optional)

For better organization, create separate repositories per service:

```bash
# Frontend repository
gcloud artifacts repositories create frontend-repo \
  --repository-format=docker \
  --location=$REGION \
  --description="Frontend container images"

# Backend repository
gcloud artifacts repositories create backend-repo \
  --repository-format=docker \
  --location=$REGION \
  --description="Backend container images"
```

## Step 6: Set Up Lifecycle Policies (Optional)

Configure automatic cleanup of old images:

```bash
# Create lifecycle policy file
cat > lifecycle-policy.yaml <<EOF
version: 1
action:
  type: DELETE
condition:
  tagState: TAGGED
  tagPrefixes:
    - "build-"
  olderThan: 30d
EOF

# Apply lifecycle policy
gcloud artifacts repositories update docker-repo \
  --location=$REGION \
  --lifecycle-policy-file=lifecycle-policy.yaml
```

## Step 7: Configure Build Integration

Update your Cloud Build configuration to use Artifact Registry:

```yaml
# In cloudbuild.yaml, use this image format:
images:
  - "${REGION}-docker.pkg.dev/${PROJECT_ID}/docker-repo/${SERVICE_NAME}:${BUILD_ID}"
  - "${REGION}-docker.pkg.dev/${PROJECT_ID}/docker-repo/${SERVICE_NAME}:latest"
```

## Step 8: Verify Setup

```bash
# List all repositories
gcloud artifacts repositories list --location=$REGION

# Get repository details
gcloud artifacts repositories describe docker-repo --location=$REGION

# List images in repository
gcloud artifacts docker images list ${REGION}-docker.pkg.dev/${PROJECT_ID}/docker-repo
```

## Image Naming Convention

Recommended naming pattern:

```
<region>-docker.pkg.dev/<project-id>/<repository>/<service-name>:<tag>
```

Examples:

- `us-central1-docker.pkg.dev/my-project/docker-repo/frontend:v1.0.0`
- `us-central1-docker.pkg.dev/my-project/docker-repo/backend:latest`
- `us-central1-docker.pkg.dev/my-project/docker-repo/api:build-123`

## Tagging Strategy

Best practices for image tagging:

1. **`latest`**: Always points to the most recent stable build
2. **`BUILD_ID`**: Unique identifier from Cloud Build (e.g., `build-abc123`)
3. **Semantic versions**: For releases (e.g., `v1.2.3`)
4. **Git commit SHA**: Short commit hash (e.g., `abc1234`)
5. **Branch names**: For feature branches (e.g., `feature-auth`)

## Verification Checklist

- [ ] Artifact Registry repository created
- [ ] Docker authentication configured
- [ ] Test image pushed successfully
- [ ] IAM permissions configured
- [ ] Cloud Build can push images
- [ ] Cloud Run can pull images
- [ ] Lifecycle policies configured (optional)

## Common Issues

### Issue: "Permission denied" when pushing images

**Solution**:

1. Verify Docker authentication: `gcloud auth configure-docker`
2. Check IAM permissions for Cloud Build service account
3. Ensure repository exists and is accessible

### Issue: "Repository not found"

**Solution**:

1. Verify repository name: `gcloud artifacts repositories list`
2. Check region matches: `--location=$REGION`
3. Ensure project ID is correct

### Issue: "Image pull failed" in Cloud Run

**Solution**:

1. Verify image exists: `gcloud artifacts docker images list`
2. Check Cloud Run service account has `artifactregistry.reader` role
3. Ensure image path matches exactly (including region)

## Cost Optimization

- **Lifecycle Policies**: Automatically delete old/unused images
- **Multi-region**: Only replicate to regions where needed
- **Cleanup Scripts**: Periodically remove old build tags
- **Image Size**: Optimize Docker images to reduce storage costs

## Next Steps

Once Artifact Registry is configured, proceed to:

- **[04. Cloud Run Setup](./04-cloud-run-setup.md)** - Configure Cloud Run services

## Additional Resources

- [Artifact Registry Documentation](https://cloud.google.com/artifact-registry/docs)
- [Docker Authentication Guide](https://cloud.google.com/artifact-registry/docs/docker/authentication)
- [Lifecycle Management](https://cloud.google.com/artifact-registry/docs/repositories/cleanup)
