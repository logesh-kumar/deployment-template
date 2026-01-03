# Upgrade Notes

## Changes in Latest Version

### Breaking Changes

1. **Timeout Format**: Timeout values now require "s" suffix
   - **Before**: `timeout = 300`
   - **After**: `timeout = "300s"` (Terraform adds suffix automatically)
   - **Action**: No changes needed in `.tfvars` files - values remain as strings

2. **Removed APIs**: 
   - `errorreporting.googleapis.com` (deprecated)
   - `dns.googleapis.com` (optional, requires billing)
   - **Action**: If you need DNS, enable it manually or add it back to the API list

3. **PORT Environment Variable**: 
   - **Removed**: PORT env var from Cloud Run services
   - **Reason**: Cloud Run automatically sets PORT
   - **Action**: Remove any PORT env vars from your configurations

### Improvements

1. **Placeholder Images**: Services now use `gcr.io/cloudrun/hello` as placeholder
   - Allows Terraform to create services before Docker images exist
   - Cloud Build updates images during deployment

2. **Lifecycle Management**: Added `ignore_changes` for images
   - Prevents Terraform from reverting Cloud Build image updates
   - Cloud Build can now update images without conflicts

3. **Port Configuration**: Added required `name = "http1"` to port blocks
   - Required by Cloud Run v2 API

## Migration Steps

1. **Update Terraform code**:
   ```bash
   git pull  # or update your copy of the template
   ```

2. **Review your `.tfvars` files**:
   - Ensure timeout values are strings (e.g., `"300"`)
   - Remove any PORT environment variables

3. **Apply changes**:
   ```bash
   terraform plan -var-file=environments/prod.tfvars
   terraform apply -var-file=environments/prod.tfvars
   ```

4. **Verify services**:
   ```bash
   gcloud run services list --region=us-central1
   ```

## Rollback

If you need to rollback, restore the previous version:
- Timeout format: Remove "s" suffix (though Terraform handles this)
- Add back deprecated APIs if needed
- Restore PORT env vars if your application requires them

