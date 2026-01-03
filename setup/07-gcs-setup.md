# 07. GCS Setup

This guide configures Google Cloud Storage buckets for file storage.

## Overview

Cloud Storage provides:

- Object storage for files, media, and static assets
- Multiple storage classes
- Lifecycle management
- CDN integration (optional)

## Step 1: Create Storage Buckets

```bash
# Source project config
source .project-config

# Create buckets for different purposes
# Uploads bucket
gsutil mb -p $PROJECT_ID -c STANDARD -l $REGION gs://${PROJECT_ID}-uploads-${ENV}

# Media bucket (for images, videos)
gsutil mb -p $PROJECT_ID -c STANDARD -l $REGION gs://${PROJECT_ID}-media-${ENV}

# Static assets bucket
gsutil mb -p $PROJECT_ID -c STANDARD -l $REGION gs://${PROJECT_ID}-static-${ENV}

# Backup bucket (for database backups)
gsutil mb -p $PROJECT_ID -c NEARLINE -l $REGION gs://${PROJECT_ID}-backups-${ENV}
```

## Step 2: Configure Bucket Permissions

Set up IAM permissions for buckets:

```bash
# Grant Cloud Run service account access
gsutil iam ch serviceAccount:cloud-run-sa@${PROJECT_ID}.iam.gserviceaccount.com:objectAdmin \
  gs://${PROJECT_ID}-uploads-${ENV}

gsutil iam ch serviceAccount:cloud-run-sa@${PROJECT_ID}.iam.gserviceaccount.com:objectAdmin \
  gs://${PROJECT_ID}-media-${ENV}

# Grant read-only access for static assets
gsutil iam ch serviceAccount:cloud-run-sa@${PROJECT_ID}.iam.gserviceaccount.com:objectViewer \
  gs://${PROJECT_ID}-static-${ENV}
```

## Step 3: Set Up Public Access (If Needed)

For public static assets:

```bash
# Make bucket publicly readable
gsutil iam ch allUsers:objectViewer gs://${PROJECT_ID}-static-${ENV}

# Or use bucket-level public access
gsutil bucketpolicyonly set on gs://${PROJECT_ID}-static-${ENV}
```

## Step 4: Configure CORS (For Web Uploads)

Enable CORS for browser-based uploads:

```bash
# Create CORS configuration file
cat > cors-config.json <<EOF
[
  {
    "origin": ["https://your-domain.com", "https://www.your-domain.com"],
    "method": ["GET", "POST", "PUT", "DELETE", "HEAD"],
    "responseHeader": ["Content-Type", "Content-Length"],
    "maxAgeSeconds": 3600
  }
]
EOF

# Apply CORS configuration
gsutil cors set cors-config.json gs://${PROJECT_ID}-uploads-${ENV}
```

## Step 5: Set Up Lifecycle Policies

Configure automatic object lifecycle management:

```bash
# Create lifecycle policy
cat > lifecycle.json <<EOF
{
  "lifecycle": {
    "rule": [
      {
        "action": {"type": "SetStorageClass", "storageClass": "NEARLINE"},
        "condition": {"age": 30}
      },
      {
        "action": {"type": "SetStorageClass", "storageClass": "COLDLINE"},
        "condition": {"age": 90}
      },
      {
        "action": {"type": "Delete"},
        "condition": {"age": 365}
      }
    ]
  }
}
EOF

# Apply lifecycle policy
gsutil lifecycle set lifecycle.json gs://${PROJECT_ID}-uploads-${ENV}
```

## Step 6: Configure Versioning (Optional)

Enable object versioning for important buckets:

```bash
# Enable versioning
gsutil versioning set on gs://${PROJECT_ID}-uploads-${ENV}

# View versions
gsutil ls -a gs://${PROJECT_ID}-uploads-${ENV}/path/to/file
```

## Step 7: Set Up Uniform Bucket-Level Access

Enable uniform access control:

```bash
# Enable uniform bucket-level access
gsutil uniformbucketlevelaccess set on gs://${PROJECT_ID}-uploads-${ENV}
```

## Step 8: Configure Environment Variables

Add bucket names to Cloud Run services:

```bash
# Backend service
gcloud run services update ${BACKEND_SERVICE} \
  --region=$REGION \
  --update-env-vars="GCS_UPLOADS_BUCKET=${PROJECT_ID}-uploads-${ENV},GCS_MEDIA_BUCKET=${PROJECT_ID}-media-${ENV},GCS_STATIC_BUCKET=${PROJECT_ID}-static-${ENV}"
```

## Step 9: Set Up Signed URLs (For Private Files)

Generate signed URLs for temporary access:

```python
# Example: Generate signed URL (Python)
from google.cloud import storage
from datetime import timedelta

storage_client = storage.Client()
bucket = storage_client.bucket(bucket_name)
blob = bucket.blob(file_path)

url = blob.generate_signed_url(
    version="v4",
    expiration=timedelta(hours=1),
    method="GET"
)
```

## Step 10: Configure CDN (Optional)

Set up Cloud CDN for static assets:

```bash
# Create backend bucket
gcloud compute backend-buckets create static-assets-backend \
  --gcs-bucket-name=${PROJECT_ID}-static-${ENV}

# Create URL map
gcloud compute url-maps create static-assets-map \
  --default-backend-bucket=static-assets-backend

# Create HTTP(S) proxy
gcloud compute target-https-proxies create static-assets-proxy \
  --url-map=static-assets-map \
  --ssl-certificates=your-ssl-cert

# Create forwarding rule
gcloud compute forwarding-rules create static-assets-rule \
  --global \
  --target-https-proxy=static-assets-proxy \
  --ports=443
```

## Step 11: Set Up Bucket Notifications (Optional)

Configure Pub/Sub notifications for bucket events:

```bash
# Create Pub/Sub topic
gcloud pubsub topics create gcs-uploads

# Create notification
gsutil notification create -t gcs-uploads -f json gs://${PROJECT_ID}-uploads-${ENV}
```

## Step 12: Test Bucket Access

Test uploading and downloading files:

```bash
# Upload test file
echo "test content" > test.txt
gsutil cp test.txt gs://${PROJECT_ID}-uploads-${ENV}/test/

# Download file
gsutil cp gs://${PROJECT_ID}-uploads-${ENV}/test/test.txt downloaded.txt

# List files
gsutil ls gs://${PROJECT_ID}-uploads-${ENV}/

# Remove test file
gsutil rm gs://${PROJECT_ID}-uploads-${ENV}/test/test.txt
```

## Step 13: Configure Retention Policies (Optional)

Set retention policies for compliance:

```bash
# Set retention policy (objects cannot be deleted for 30 days)
gsutil retention set 30d gs://${PROJECT_ID}-backups-${ENV}
```

## Bucket Organization Structure

Recommended bucket structure:

```
gs://project-id-uploads-prod/
  ├── users/
  │   ├── {userId}/
  │   │   ├── avatars/
  │   │   └── documents/
  ├── temp/
  └── processed/

gs://project-id-media-prod/
  ├── images/
  │   ├── thumbnails/
  │   └── originals/
  ├── videos/
  └── audio/

gs://project-id-static-prod/
  ├── css/
  ├── js/
  ├── images/
  └── fonts/
```

## Verification Checklist

- [ ] Buckets created for all purposes
- [ ] IAM permissions configured
- [ ] CORS configured (if needed)
- [ ] Lifecycle policies set
- [ ] Environment variables updated
- [ ] Upload/download tested
- [ ] Signed URLs working (if needed)
- [ ] CDN configured (optional)

## Common Issues

### Issue: "Access denied" when accessing bucket

**Solution**:

1. Verify IAM permissions
2. Check service account has correct roles
3. Ensure uniform bucket-level access is configured

### Issue: "CORS error" in browser

**Solution**:

1. Verify CORS configuration
2. Check origin is in allowed list
3. Ensure methods and headers are correct

### Issue: "Bucket not found"

**Solution**:

1. Verify bucket name is correct
2. Check project ID matches
3. Ensure bucket exists in correct region

## Best Practices

1. **Bucket Naming**: Use consistent naming convention (`project-purpose-env`)
2. **Storage Classes**: Use appropriate classes (Standard, Nearline, Coldline)
3. **Lifecycle Policies**: Automatically move/delete old objects
4. **Versioning**: Enable for important data
5. **Access Control**: Use IAM, not ACLs (uniform bucket-level access)
6. **Signed URLs**: Use for temporary private access
7. **CDN**: Use Cloud CDN for static assets
8. **Monitoring**: Set up alerts for bucket usage
9. **Backup**: Regular backups of critical data
10. **Cost Optimization**: Use lifecycle policies to reduce costs

## Next Steps

Once GCS is configured, proceed to:

- **[08. Domain Mapping](./08-domain-mapping.md)** - Set up custom domains and SSL

## Additional Resources

- [Cloud Storage Documentation](https://cloud.google.com/storage/docs)
- [Cloud Storage Best Practices](https://cloud.google.com/storage/docs/best-practices)
- [Signed URLs Guide](https://cloud.google.com/storage/docs/access-control/signing-urls-with-helpers)
