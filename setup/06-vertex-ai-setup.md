# 06. Vertex AI Setup

This guide configures Vertex AI for AI/ML model hosting and inference.

## Overview

Vertex AI provides:

- Pre-trained model APIs (Vision, Language, etc.)
- Custom model deployment
- Batch and online predictions
- AutoML capabilities

## Step 1: Enable Vertex AI API

```bash
# Source project config
source .project-config

# Enable Vertex AI API
gcloud services enable aiplatform.googleapis.com
```

## Step 2: Set Up Vertex AI Project

```bash
# Set default region for Vertex AI
gcloud config set ai/region $REGION

# Verify API is enabled
gcloud services list --enabled | grep aiplatform
```

## Step 3: Create Vertex AI Dataset (If Using AutoML)

```bash
# Create dataset for custom models (optional)
gcloud ai datasets create \
  --display-name="my-dataset" \
  --metadata-schema-uri="gs://google-cloud-aiplatform/schema/dataset/metadata/image_1.0.0.yaml" \
  --region=$REGION
```

## Step 4: Deploy Pre-trained Models

### Using Vertex AI API (Python Example)

```python
from google.cloud import aiplatform

# Initialize Vertex AI
aiplatform.init(project=PROJECT_ID, location=REGION)

# Use pre-trained models (e.g., Vision API)
from google.cloud import vision
client = vision.ImageAnnotatorClient()
```

### Using REST API

```bash
# Example: Text-to-Speech API
curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  "https://${REGION}-aiplatform.googleapis.com/v1/projects/${PROJECT_ID}/locations/${REGION}/models"
```

## Step 5: Deploy Custom Model (If Needed)

```bash
# Upload model to Cloud Storage first
gsutil cp model.pkl gs://${PROJECT_ID}-models/model.pkl

# Create model endpoint
gcloud ai models upload \
  --display-name="my-custom-model" \
  --container-image-uri="gcr.io/cloud-aiplatform/prediction/pytorch-cpu.1-13:latest" \
  --artifact-uri="gs://${PROJECT_ID}-models/" \
  --region=$REGION

# Deploy model to endpoint
gcloud ai endpoints create \
  --display-name="my-endpoint" \
  --region=$REGION

# Deploy model to endpoint
ENDPOINT_ID=$(gcloud ai endpoints list --region=$REGION --format="value(name)" --filter="displayName:my-endpoint" | cut -d'/' -f6)
MODEL_ID=$(gcloud ai models list --region=$REGION --format="value(name)" --filter="displayName:my-custom-model" | cut -d'/' -f6)

gcloud ai endpoints deploy-model $ENDPOINT_ID \
  --model=$MODEL_ID \
  --display-name="deployed-model" \
  --min-replica-count=1 \
  --max-replica-count=3 \
  --region=$REGION
```

## Step 6: Configure Service Account Access

Grant Cloud Run service account access to Vertex AI:

```bash
# Grant Vertex AI User role
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:cloud-run-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/aiplatform.user"
```

## Step 7: Set Up Vertex AI Endpoint URL

Get your endpoint URL for use in application:

```bash
# List endpoints
gcloud ai endpoints list --region=$REGION

# Get endpoint details
ENDPOINT_ID="your-endpoint-id"
gcloud ai endpoints describe $ENDPOINT_ID --region=$REGION
```

## Step 8: Configure Environment Variables

Add Vertex AI configuration to Cloud Run:

```bash
# Add Vertex AI endpoint to backend service
gcloud run services update ${BACKEND_SERVICE} \
  --region=$REGION \
  --update-env-vars="VERTEX_AI_ENDPOINT=https://${REGION}-aiplatform.googleapis.com,VERTEX_AI_PROJECT=${PROJECT_ID},VERTEX_AI_LOCATION=${REGION}"
```

## Step 9: Test Vertex AI Integration

Test from your application:

```python
# Example: Using Vertex AI from Cloud Run
from google.cloud import aiplatform

aiplatform.init(project=PROJECT_ID, location=REGION)

# Make prediction
endpoint = aiplatform.Endpoint(endpoint_name=ENDPOINT_ID)
prediction = endpoint.predict(instances=[...])
```

## Step 10: Set Up Monitoring

Monitor Vertex AI usage:

```bash
# View model predictions
gcloud ai operations list --region=$REGION

# Monitor endpoint traffic
gcloud monitoring dashboards create --config-from-file=dashboard.json
```

## Step 11: Configure Auto-scaling

Set up automatic scaling for endpoints:

```bash
# Update endpoint with auto-scaling
gcloud ai endpoints update $ENDPOINT_ID \
  --region=$REGION \
  --min-replica-count=1 \
  --max-replica-count=10 \
  --enable-autoscaling
```

## Step 12: Set Up Batch Predictions (Optional)

For batch processing:

```bash
# Create batch prediction job
gcloud ai batch-prediction-jobs create \
  --display-name="batch-prediction" \
  --model=$MODEL_ID \
  --input-format="jsonl" \
  --instances-format="jsonl" \
  --input-paths="gs://${PROJECT_ID}-data/input/*.jsonl" \
  --output-path="gs://${PROJECT_ID}-data/output/" \
  --region=$REGION
```

## Verification Checklist

- [ ] Vertex AI API enabled
- [ ] Service account has Vertex AI permissions
- [ ] Model deployed (if using custom models)
- [ ] Endpoint created and accessible
- [ ] Environment variables configured
- [ ] Integration tested
- [ ] Monitoring configured

## Common Issues

### Issue: "Permission denied" accessing Vertex AI

**Solution**:

1. Verify service account has `roles/aiplatform.user`
2. Check API is enabled
3. Ensure region matches

### Issue: "Endpoint not found"

**Solution**:

1. Verify endpoint ID is correct
2. Check region matches
3. Ensure endpoint is deployed

### Issue: "Model prediction timeout"

**Solution**:

1. Increase Cloud Run timeout
2. Optimize model inference
3. Use batch predictions for large datasets

## Best Practices

1. **Use Pre-trained Models**: Leverage Google's pre-trained models when possible
2. **Regional Endpoints**: Deploy models in the same region as your services
3. **Auto-scaling**: Enable auto-scaling for variable workloads
4. **Monitoring**: Set up alerts for prediction errors
5. **Cost Optimization**: Use batch predictions for non-real-time workloads
6. **Caching**: Cache predictions when appropriate
7. **Error Handling**: Implement retry logic for API calls

## Next Steps

Once Vertex AI is configured, proceed to:

- **[07. GCS Setup](./07-gcs-setup.md)** - Configure Cloud Storage buckets

## Additional Resources

- [Vertex AI Documentation](https://cloud.google.com/vertex-ai/docs)
- [Vertex AI Python SDK](https://cloud.google.com/python/docs/reference/aiplatform/latest)
- [Pre-trained Models](https://cloud.google.com/ai-platform/docs/getting-started-vertex-ai)
