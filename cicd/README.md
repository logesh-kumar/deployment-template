# CI/CD Templates

This directory contains Cloud Build configuration templates for automated deployments.

## Files

- **`cloudbuild.backend.yaml`** - Backend service deployment template
- **`cloudbuild.frontend.yaml`** - Frontend service deployment template

## Usage

### 1. Copy Templates to Your Project

```bash
# Copy backend template
cp cicd/cloudbuild.backend.yaml cloudbuild.backend.yaml

# Copy frontend template
cp cicd/cloudbuild.frontend.yaml cloudbuild.frontend.yaml
```

### 2. Customize for Your Project

Edit the copied files and customize:

- **Substitutions**: Update default values for your project
- **Build Steps**: Add/remove steps (tests, migrations, etc.)
- **Dockerfile Path**: Set correct path to your Dockerfile
- **Secrets**: Update secret names to match your Secret Manager secrets
- **Resource Limits**: Adjust CPU, memory, and scaling based on your needs

### 3. Create Cloud Build Triggers

```bash
# Backend trigger
gcloud builds triggers create github \
  --name="deploy-backend" \
  --repo-name="your-repo" \
  --repo-owner="your-org" \
  --branch-pattern="^main$" \
  --build-config="cloudbuild.backend.yaml" \
  --substitutions="_SERVICE_NAME=your-backend,_REGION=us-central1,_ENV=prod"

# Frontend trigger
gcloud builds triggers create github \
  --name="deploy-frontend" \
  --repo-name="your-repo" \
  --repo-owner="your-org" \
  --branch-pattern="^main$" \
  --build-config="cloudbuild.frontend.yaml" \
  --substitutions="_SERVICE_NAME=your-frontend,_REGION=us-central1,_ENV=prod"
```

### 4. Manual Deployment

Test deployments manually:

```bash
# Backend
gcloud builds submit --config=cloudbuild.backend.yaml \
  --substitutions="_SERVICE_NAME=your-backend,_REGION=us-central1,_ENV=prod"

# Frontend
gcloud builds submit --config=cloudbuild.frontend.yaml \
  --substitutions="_SERVICE_NAME=your-frontend,_REGION=us-central1,_ENV=prod"
```

## Substitutions

### Backend Template

| Variable           | Description             | Example                  |
| ------------------ | ----------------------- | ------------------------ |
| `_SERVICE_NAME`    | Cloud Run service name  | `my-api`                 |
| `_REGION`          | GCP region              | `us-central1`            |
| `_ENV`             | Environment             | `dev`, `staging`, `prod` |
| `_DOCKERFILE_PATH` | Path to Dockerfile      | `apps/api/Dockerfile`    |
| `_BUILD_CONTEXT`   | Build context directory | `.`                      |

### Frontend Template

| Variable           | Description             | Example                  |
| ------------------ | ----------------------- | ------------------------ |
| `_SERVICE_NAME`    | Cloud Run service name  | `my-app`                 |
| `_REGION`          | GCP region              | `us-central1`            |
| `_ENV`             | Environment             | `dev`, `staging`, `prod` |
| `_DOCKERFILE_PATH` | Path to Dockerfile      | `apps/web/Dockerfile`    |
| `_BUILD_CONTEXT`   | Build context directory | `.`                      |

## Customization Examples

### Adding Database Migrations

Uncomment and customize the migration step in `cloudbuild.backend.yaml`:

```yaml
- name: "node:20-alpine"
  entrypoint: "sh"
  args:
    - "-c"
    - |
      npm install --frozen-lockfile
      npm run db:migrate
  secretEnv: ["DATABASE_URL"]
```

### Adding Tests

Add a test step before building:

```yaml
- name: "node:20-alpine"
  entrypoint: "sh"
  args:
    - "-c"
    - |
      npm install --frozen-lockfile
      npm run test
  id: "run-tests"
```

### Environment-Specific Configuration

Use substitutions for different environments:

```bash
# Development
--substitutions="_ENV=dev,_SERVICE_NAME=backend-dev"

# Staging
--substitutions="_ENV=staging,_SERVICE_NAME=backend-staging"

# Production
--substitutions="_ENV=prod,_SERVICE_NAME=backend-prod"
```

## Secrets Management

### Backend Secrets

Secrets are injected via `--update-secrets` flag:

```yaml
- "--update-secrets"
- "DATABASE_URL=database-url:latest,API_KEY=api-key:latest"
```

**Format**: `ENV_VAR_NAME=secret-name:version`

- Use `:latest` to always get the latest version
- Use `:1`, `:2`, etc. for specific versions

### Frontend Build Args

Frontend uses build-time arguments (public values only):

```yaml
- "--build-arg"
- "NEXT_PUBLIC_API_URL=https://api.example.com"
```

**Never use build args for secrets!** Only use for public configuration values.

## Best Practices

1. **Separate Configs**: Use separate configs for frontend and backend
2. **Path Filters**: Configure triggers to only build when relevant files change
3. **Branch Strategy**: Use different triggers for different branches/environments
4. **Secrets**: Always use Secret Manager, never hardcode secrets
5. **Build Args**: Only use build args for public, non-sensitive values
6. **Timeouts**: Set appropriate timeouts for your build process
7. **Machine Type**: Use appropriate machine types (E2_HIGHCPU_8 for faster builds)
8. **Tags**: Tag builds for better organization and filtering
9. **Logging**: Use CLOUD_LOGGING_ONLY for centralized logs
10. **Testing**: Always test builds manually before setting up triggers

## Troubleshooting

### Build Fails: "Permission denied"

- Verify Cloud Build service account has necessary permissions
- Check IAM roles: `roles/run.admin`, `roles/iam.serviceAccountUser`

### Build Fails: "Image not found"

- Verify Artifact Registry repository exists
- Check image path format matches repository location
- Ensure Docker authentication is configured

### Build Fails: "Secret not found"

- Verify secrets exist in Secret Manager
- Check secret names match exactly (case-sensitive)
- Ensure Cloud Run service account has Secret Manager access

### Deployment Fails: "Service not found"

- Verify Cloud Run service exists
- Check service name matches exactly
- Ensure region is correct

## Additional Resources

- [Cloud Build Documentation](https://cloud.google.com/build/docs)
- [Cloud Build Configuration Reference](https://cloud.google.com/build/docs/build-config)
- [Cloud Run Deployment](https://cloud.google.com/run/docs/deploying)
