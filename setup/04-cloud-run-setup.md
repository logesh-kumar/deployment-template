# 04. Cloud Run Setup

This guide configures Cloud Run services for frontend and backend applications.

## Overview

Cloud Run is a serverless container platform. We'll set up:

- **Frontend Service**: Serves web application
- **Backend Service**: Runs API server

## Step 1: Prepare Docker Images

Ensure your Docker images are built and pushed to Artifact Registry (see [03. Artifact Registry](./03-artifact-registry.md)).

## Step 2: Deploy Frontend Service

```bash
# Source project config
source .project-config

# Deploy frontend service
gcloud run deploy ${FRONTEND_SERVICE} \
  --image=${REGION}-docker.pkg.dev/${PROJECT_ID}/docker-repo/${FRONTEND_SERVICE}:latest \
  --region=$REGION \
  --platform=managed \
  --allow-unauthenticated \
  --service-account=cloud-run-sa@${PROJECT_ID}.iam.gserviceaccount.com \
  --memory=512Mi \
  --cpu=1 \
  --min-instances=0 \
  --max-instances=10 \
  --timeout=60 \
  --port=8080 \
  --set-env-vars="NODE_ENV=production"
```

## Step 3: Deploy Backend Service

```bash
# Deploy backend service
gcloud run deploy ${BACKEND_SERVICE} \
  --image=${REGION}-docker.pkg.dev/${PROJECT_ID}/docker-repo/${BACKEND_SERVICE}:latest \
  --region=$REGION \
  --platform=managed \
  --allow-unauthenticated \
  --service-account=cloud-run-sa@${PROJECT_ID}.iam.gserviceaccount.com \
  --memory=1Gi \
  --cpu=1 \
  --min-instances=0 \
  --max-instances=10 \
  --timeout=300 \
  --port=8080 \
  --set-env-vars="NODE_ENV=production" \
  --update-secrets="DATABASE_URL=database-url:latest,API_KEY=api-key:latest"
```

**Note**: Replace secret names with your actual Secret Manager secret names.

## Step 4: Configure Service Settings

### Frontend Configuration

```bash
# Update frontend service configuration
gcloud run services update ${FRONTEND_SERVICE} \
  --region=$REGION \
  --memory=1Gi \
  --cpu=2 \
  --concurrency=80 \
  --max-instances=20
```

### Backend Configuration

```bash
# Update backend service configuration
gcloud run services update ${BACKEND_SERVICE} \
  --region=$REGION \
  --memory=2Gi \
  --cpu=2 \
  --concurrency=100 \
  --max-instances=50 \
  --timeout=300
```

## Step 5: Set Up Health Checks

Cloud Run automatically uses HTTP health checks. Ensure your services have health endpoints:

**Frontend** (serves static files, no health check needed typically):

```bash
# Health check is automatic for static file serving
```

**Backend** (should implement `/health` endpoint):

```bash
# Example: Your backend should have a /health endpoint
# Cloud Run will check: GET https://your-service.run.app/health
```

## Step 6: Configure Environment Variables

Set environment-specific variables:

```bash
# Frontend environment variables
gcloud run services update ${FRONTEND_SERVICE} \
  --region=$REGION \
  --update-env-vars="NEXT_PUBLIC_API_URL=https://${BACKEND_SERVICE}-${PROJECT_HASH}-${REGION}.a.run.app,NODE_ENV=production"

# Backend environment variables
gcloud run services update ${BACKEND_SERVICE} \
  --region=$REGION \
  --update-env-vars="NODE_ENV=production,LOG_LEVEL=info"
```

## Step 7: Configure Secrets from Secret Manager

Inject secrets as environment variables:

```bash
# Backend secrets
gcloud run services update ${BACKEND_SERVICE} \
  --region=$REGION \
  --update-secrets="DATABASE_URL=database-url:latest,DIRECT_URL=direct-url:latest,API_KEY=api-key:latest,JWT_SECRET=jwt-secret:latest"
```

**Note**: Secrets are mounted as environment variables. Use `:latest` to always get the latest version, or `:1` for a specific version.

## Step 8: Set Up VPC Connector (Optional)

For private networking to Cloud SQL or other VPC resources:

```bash
# Create VPC connector (if not exists)
gcloud compute networks vpc-access connectors create cloud-run-connector \
  --region=$REGION \
  --subnet=default \
  --subnet-project=$PROJECT_ID \
  --min-instances=2 \
  --max-instances=3

# Update service to use VPC connector
gcloud run services update ${BACKEND_SERVICE} \
  --region=$REGION \
  --vpc-connector=cloud-run-connector \
  --vpc-egress=private-ranges-only
```

## Step 9: Configure CORS (Backend)

If your backend needs to accept requests from frontend:

```bash
# CORS is typically handled in application code
# But you can set CORS headers via Cloud Run:
gcloud run services update ${BACKEND_SERVICE} \
  --region=$REGION \
  --update-env-vars="CORS_ORIGIN=https://your-frontend-domain.com"
```

## Step 10: Set Up Request Timeouts

Configure appropriate timeouts:

```bash
# Frontend (short timeout for static content)
gcloud run services update ${FRONTEND_SERVICE} \
  --region=$REGION \
  --timeout=60

# Backend (longer timeout for API processing)
gcloud run services update ${BACKEND_SERVICE} \
  --region=$REGION \
  --timeout=300
```

## Step 11: Configure Scaling

### Development Environment

```bash
# Dev: Scale to zero, low resources
gcloud run services update ${FRONTEND_SERVICE} \
  --region=$REGION \
  --min-instances=0 \
  --max-instances=5 \
  --memory=512Mi \
  --cpu=1

gcloud run services update ${BACKEND_SERVICE} \
  --region=$REGION \
  --min-instances=0 \
  --max-instances=5 \
  --memory=1Gi \
  --cpu=1
```

### Production Environment

```bash
# Prod: Always available, higher resources
gcloud run services update ${FRONTEND_SERVICE} \
  --region=$REGION \
  --min-instances=1 \
  --max-instances=50 \
  --memory=1Gi \
  --cpu=2

gcloud run services update ${BACKEND_SERVICE} \
  --region=$REGION \
  --min-instances=1 \
  --max-instances=100 \
  --memory=2Gi \
  --cpu=2
```

## Step 12: Get Service URLs

```bash
# Get frontend URL
FRONTEND_URL=$(gcloud run services describe ${FRONTEND_SERVICE} \
  --region=$REGION \
  --format="value(status.url)")

# Get backend URL
BACKEND_URL=$(gcloud run services describe ${BACKEND_SERVICE} \
  --region=$REGION \
  --format="value(status.url)")

echo "Frontend URL: $FRONTEND_URL"
echo "Backend URL: $BACKEND_URL"
```

## Step 13: Test Services

```bash
# Test frontend
curl $FRONTEND_URL

# Test backend health endpoint
curl $BACKEND_URL/health

# Test backend API
curl $BACKEND_URL/api/status
```

## Step 14: View Service Logs

```bash
# View frontend logs
gcloud run services logs read ${FRONTEND_SERVICE} --region=$REGION --limit=50

# View backend logs
gcloud run services logs read ${BACKEND_SERVICE} --region=$REGION --limit=50

# Stream logs in real-time
gcloud run services logs tail ${BACKEND_SERVICE} --region=$REGION
```

## Step 15: Configure Traffic Splitting (Optional)

For gradual rollouts or A/B testing:

```bash
# Deploy new revision without routing traffic
gcloud run deploy ${BACKEND_SERVICE} \
  --image=${REGION}-docker.pkg.dev/${PROJECT_ID}/docker-repo/${BACKEND_SERVICE}:new-version \
  --region=$REGION \
  --no-traffic

# Split traffic 90% old, 10% new
gcloud run services update-traffic ${BACKEND_SERVICE} \
  --region=$REGION \
  --to-revisions=REVISION-1=90,REVISION-2=10
```

## Service Configuration Summary

| Setting       | Frontend           | Backend            |
| ------------- | ------------------ | ------------------ |
| Memory        | 512Mi - 1Gi        | 1Gi - 4Gi          |
| CPU           | 1-2 vCPU           | 1-4 vCPU           |
| Min Instances | 0 (dev) / 1 (prod) | 0 (dev) / 1 (prod) |
| Max Instances | 10-50              | 10-100             |
| Timeout       | 60s                | 300s               |
| Concurrency   | 80                 | 100                |

## Verification Checklist

- [ ] Frontend service deployed and accessible
- [ ] Backend service deployed and accessible
- [ ] Health checks working
- [ ] Environment variables configured
- [ ] Secrets injected from Secret Manager
- [ ] Service URLs obtained
- [ ] Services tested and responding
- [ ] Logs accessible
- [ ] Scaling configured appropriately

## Common Issues

### Issue: "Image not found"

**Solution**:

1. Verify image exists in Artifact Registry
2. Check image path matches exactly
3. Ensure Cloud Run service account has read access

### Issue: "Permission denied"

**Solution**:

1. Verify service account has necessary permissions
2. Check Secret Manager access
3. Ensure IAM roles are correctly assigned

### Issue: "Service timeout"

**Solution**:

1. Increase timeout: `--timeout=600`
2. Optimize application code
3. Check for long-running operations

### Issue: "Cold start latency"

**Solution**:

1. Set `--min-instances=1` for production
2. Optimize Docker image size
3. Use faster initialization in code

## Best Practices

1. **Health Endpoints**: Always implement `/health` endpoints
2. **Graceful Shutdowns**: Handle SIGTERM signals
3. **Stateless Services**: Don't store state in containers
4. **Resource Limits**: Set appropriate CPU/memory limits
5. **Logging**: Use structured logging (JSON)
6. **Monitoring**: Set up alerts for errors and latency
7. **Secrets**: Always use Secret Manager, never hardcode
8. **Environment Variables**: Use for non-sensitive config
9. **Traffic Splitting**: Use for zero-downtime deployments
10. **Cost Optimization**: Scale to zero in dev, min instances in prod

## Next Steps

Once Cloud Run services are configured, proceed to:

- **[05. Cloud Build Setup](./05-cloud-build-setup.md)** - Configure CI/CD pipelines

## Additional Resources

- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Cloud Run Best Practices](https://cloud.google.com/run/docs/tips)
- [Cloud Run Pricing](https://cloud.google.com/run/pricing)
