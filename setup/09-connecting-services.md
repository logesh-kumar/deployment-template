# 09. Connecting Services

This guide covers the final integration steps to connect all services together.

## Overview

This guide ensures:

- Services can communicate with each other
- Environment variables are correctly configured
- Secrets are accessible
- Monitoring is set up
- Everything works end-to-end

## Step 1: Verify Service URLs

Get all service URLs:

```bash
# Source project config
source .project-config

# Get Cloud Run service URLs
FRONTEND_URL=$(gcloud run services describe ${FRONTEND_SERVICE} \
  --region=$REGION \
  --format="value(status.url)")

BACKEND_URL=$(gcloud run services describe ${BACKEND_SERVICE} \
  --region=$REGION \
  --format="value(status.url)")

# Get custom domain URLs (if configured)
FRONTEND_DOMAIN="https://app.example.com"
BACKEND_DOMAIN="https://api.example.com"

echo "Frontend URL: $FRONTEND_URL"
echo "Backend URL: $BACKEND_URL"
echo "Frontend Domain: $FRONTEND_DOMAIN"
echo "Backend Domain: $BACKEND_DOMAIN"
```

## Step 2: Configure Frontend-Backend Communication

Update frontend to use backend URL:

```bash
# Update frontend environment variables
gcloud run services update ${FRONTEND_SERVICE} \
  --region=$REGION \
  --update-env-vars="NEXT_PUBLIC_API_URL=${BACKEND_DOMAIN},NEXT_PUBLIC_ENV=production"
```

## Step 3: Configure Backend CORS

Allow frontend to make requests to backend:

```bash
# Update backend CORS settings
gcloud run services update ${BACKEND_SERVICE} \
  --region=$REGION \
  --update-env-vars="CORS_ORIGIN=${FRONTEND_DOMAIN},FRONTEND_URL=${FRONTEND_DOMAIN}"
```

## Step 4: Verify Secret Manager Integration

Ensure all secrets are accessible:

```bash
# List all secrets
gcloud secrets list

# Verify secrets are accessible by Cloud Run service account
gcloud projects get-iam-policy $PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:cloud-run-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --format="table(bindings.role)"
```

## Step 5: Test Service Communication

### Test Backend Health

```bash
# Test backend health endpoint
curl ${BACKEND_URL}/health
curl ${BACKEND_DOMAIN}/health
```

### Test Frontend

```bash
# Test frontend
curl -I ${FRONTEND_URL}
curl -I ${FRONTEND_DOMAIN}
```

### Test Frontend → Backend Communication

```bash
# Test API call from frontend perspective
curl -H "Origin: ${FRONTEND_DOMAIN}" \
  -H "Access-Control-Request-Method: GET" \
  -H "Access-Control-Request-Headers: Content-Type" \
  -X OPTIONS \
  ${BACKEND_DOMAIN}/api/status
```

## Step 6: Configure Cloud Storage Access

Verify Cloud Storage buckets are accessible:

```bash
# List buckets
gsutil ls

# Test upload (from Cloud Run, this should work via service account)
# Test in your application code
```

## Step 7: Configure Vertex AI Access (If Used)

Verify Vertex AI is accessible:

```bash
# Test Vertex AI endpoint (if configured)
# This should be tested in your application code
```

## Step 8: Set Up Monitoring and Alerts

### Create Alert Policies

```bash
# Create alert for high error rate
gcloud alpha monitoring policies create \
  --notification-channels=CHANNEL_ID \
  --display-name="High Error Rate" \
  --condition-threshold-value=10 \
  --condition-threshold-duration=300s \
  --condition-filter='resource.type="cloud_run_revision" AND metric.type="run.googleapis.com/request_count" AND metric.label.response_code_class="5xx"'
```

### Set Up Log-based Metrics

```bash
# Create log-based metric for custom errors
gcloud logging metrics create custom_error_count \
  --description="Count of custom application errors" \
  --log-filter='resource.type="cloud_run_revision" AND severity>=ERROR'
```

## Step 9: Configure Logging

Ensure logs are properly configured:

```bash
# View recent logs
gcloud run services logs read ${BACKEND_SERVICE} --region=$REGION --limit=50

# Set up log exports (optional)
gcloud logging sinks create cloud-run-logs \
  bigquery.googleapis.com/projects/${PROJECT_ID}/datasets/cloud_run_logs \
  --log-filter='resource.type="cloud_run_revision"'
```

## Step 10: Set Up Error Reporting

Enable Error Reporting:

```bash
# Error Reporting is automatically enabled for Cloud Run
# View errors in Console: https://console.cloud.google.com/errors

# Or via CLI
gcloud error-reporting events list --service=${BACKEND_SERVICE}
```

## Step 11: Configure Uptime Checks

Set up uptime monitoring:

```bash
# Create uptime check for frontend
gcloud monitoring uptime create app.example.com \
  --display-name="Frontend Uptime Check" \
  --http-check-path="/" \
  --http-check-port=443

# Create uptime check for backend
gcloud monitoring uptime create api.example.com \
  --display-name="Backend Uptime Check" \
  --http-check-path="/health" \
  --http-check-port=443
```

## Step 12: Test End-to-End Flow

### Complete User Flow Test

```bash
# 1. Access frontend
curl -I ${FRONTEND_DOMAIN}

# 2. Frontend makes API call to backend
curl -H "Origin: ${FRONTEND_DOMAIN}" \
  ${BACKEND_DOMAIN}/api/status

# 3. Backend accesses database (tested in application)

# 4. Backend accesses Cloud Storage (tested in application)

# 5. Backend calls Vertex AI (if used, tested in application)
```

## Step 13: Create Integration Test Script

Create a test script to verify all connections:

```bash
cat > test-integration.sh <<'EOF'
#!/bin/bash
set -e

source .project-config

echo "Testing Frontend..."
curl -f -I ${FRONTEND_DOMAIN} || exit 1

echo "Testing Backend Health..."
curl -f ${BACKEND_DOMAIN}/health || exit 1

echo "Testing CORS..."
curl -f -H "Origin: ${FRONTEND_DOMAIN}" \
  -H "Access-Control-Request-Method: GET" \
  -X OPTIONS \
  ${BACKEND_DOMAIN}/api/status || exit 1

echo "All integration tests passed!"
EOF

chmod +x test-integration.sh
./test-integration.sh
```

## Step 14: Document Service Dependencies

Create a service dependency diagram:

```bash
cat > SERVICE_DEPENDENCIES.md <<EOF
# Service Dependencies

## Frontend Service
- Depends on: Backend API
- Environment Variables:
  - NEXT_PUBLIC_API_URL: Backend domain
- Secrets: None (public service)

## Backend Service
- Depends on:
  - Cloud SQL / PostgreSQL (database)
  - Cloud Storage (file storage)
  - Vertex AI (AI models, if used)
  - Secret Manager (secrets)
- Environment Variables:
  - CORS_ORIGIN: Frontend domain
  - DATABASE_URL: From Secret Manager
  - GCS_BUCKET: Cloud Storage bucket name
- Secrets:
  - DATABASE_URL
  - API_KEYS
  - JWT_SECRETS
EOF
```

## Step 15: Set Up Backup and Recovery

### Database Backups

```bash
# If using Cloud SQL, set up automated backups
gcloud sql instances patch INSTANCE_NAME \
  --backup-start-time=03:00 \
  --enable-bin-log
```

### Cloud Storage Backups

```bash
# Set up lifecycle policy for backups (already configured in GCS setup)
# Verify backup bucket exists
gsutil ls gs://${PROJECT_ID}-backups-${ENV}/
```

## Step 16: Performance Testing

Test service performance:

```bash
# Load test frontend
ab -n 1000 -c 10 ${FRONTEND_DOMAIN}/

# Load test backend
ab -n 1000 -c 10 ${BACKEND_DOMAIN}/api/status
```

## Step 17: Security Checklist

Verify security configuration:

- [ ] HTTPS enforced (no HTTP access)
- [ ] CORS properly configured
- [ ] Secrets in Secret Manager (not in code)
- [ ] Service accounts have least privilege
- [ ] IAM roles are correctly assigned
- [ ] Cloud Storage buckets have proper permissions
- [ ] Domain mapping uses managed SSL certificates
- [ ] Error messages don't expose sensitive information

## Step 18: Cost Optimization Review

Review and optimize costs:

```bash
# Check Cloud Run usage
gcloud run services describe ${FRONTEND_SERVICE} --region=$REGION \
  --format="value(spec.template.spec.containers[0].resources)"

# Check Cloud Storage usage
gsutil du -sh gs://${PROJECT_ID}-*/

# Review billing
gcloud billing accounts list
```

## Verification Checklist

- [ ] All service URLs obtained and documented
- [ ] Frontend → Backend communication working
- [ ] CORS configured correctly
- [ ] Secrets accessible from Cloud Run
- [ ] Cloud Storage accessible
- [ ] Vertex AI accessible (if used)
- [ ] Monitoring and alerts configured
- [ ] Logging configured
- [ ] Error reporting enabled
- [ ] Uptime checks configured
- [ ] End-to-end flow tested
- [ ] Integration tests passing
- [ ] Security checklist completed
- [ ] Cost optimization reviewed

## Troubleshooting Guide

### Issue: Frontend can't reach backend

**Solution**:

1. Verify backend URL in frontend env vars
2. Check CORS configuration
3. Verify backend is accessible
4. Check network connectivity

### Issue: Secrets not accessible

**Solution**:

1. Verify service account has Secret Manager access
2. Check secret names match exactly
3. Verify secrets exist in Secret Manager
4. Check IAM bindings

### Issue: Cloud Storage access denied

**Solution**:

1. Verify service account has Storage permissions
2. Check bucket IAM policies
3. Verify bucket names are correct
4. Check uniform bucket-level access

## Next Steps

Your GCP deployment is now complete! Consider:

1. **Documentation**: Document your specific setup
2. **Monitoring**: Set up dashboards in Cloud Monitoring
3. **Alerts**: Configure alerting for critical issues
4. **Backup Strategy**: Implement regular backups
5. **Disaster Recovery**: Plan for disaster scenarios
6. **Scaling**: Monitor and adjust scaling parameters
7. **Cost Optimization**: Regularly review and optimize costs

## Additional Resources

- [Cloud Run Best Practices](https://cloud.google.com/run/docs/tips)
- [GCP Security Best Practices](https://cloud.google.com/security/best-practices)
- [Monitoring and Alerting](https://cloud.google.com/monitoring/docs)

---

**Congratulations!** Your GCP deployment is ready for production use. 🎉
