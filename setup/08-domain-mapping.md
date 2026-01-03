# 08. Domain Mapping

This guide configures custom domain names and SSL certificates for Cloud Run services.

## Overview

Domain mapping provides:

- Custom domain names (e.g., `api.example.com`)
- Automatic SSL certificate provisioning
- DNS management integration
- Load balancer configuration

## Step 1: Prepare Domain Names

Decide on your domain structure:

- **Frontend**: `app.example.com` or `www.example.com`
- **Backend**: `api.example.com` or `backend.example.com`

## Step 2: Create Domain Mappings

### Frontend Domain Mapping

```bash
# Source project config
source .project-config

# Map domain to frontend service
gcloud run domain-mappings create \
  --service=${FRONTEND_SERVICE} \
  --domain=app.example.com \
  --region=$REGION
```

### Backend Domain Mapping

```bash
# Map domain to backend service
gcloud run domain-mappings create \
  --service=${BACKEND_SERVICE} \
  --domain=api.example.com \
  --region=$REGION
```

## Step 3: Get DNS Records

After creating domain mappings, get the DNS records to configure:

```bash
# Get frontend DNS records
gcloud run domain-mappings describe app.example.com --region=$REGION

# Get backend DNS records
gcloud run domain-mappings describe api.example.com --region=$REGION
```

Example output:

```
Name: app.example.com
...
Status:
  Conditions:
    - Type: Ready
      Status: True
  ResourceRecords:
    - Name: app.example.com
      Type: A
      Rrdata: 34.120.xxx.xxx
    - Name: app.example.com
      Type: AAAA
      Rrdata: 2600:1901:xxxx:xxxx::xxxx
```

## Step 4: Configure DNS Records

### Option A: Using Cloud DNS (Recommended)

```bash
# Create DNS zone (if not exists)
gcloud dns managed-zones create example-com \
  --dns-name=example.com \
  --description="DNS zone for example.com"

# Get zone name
ZONE_NAME=$(gcloud dns managed-zones list --filter="dnsName:example.com" --format="value(name)")

# Add A record for frontend
gcloud dns record-sets create app.example.com \
  --zone=$ZONE_NAME \
  --type=A \
  --rrdatas="34.120.xxx.xxx" \
  --ttl=300

# Add AAAA record for frontend (IPv6)
gcloud dns record-sets create app.example.com \
  --zone=$ZONE_NAME \
  --type=AAAA \
  --rrdatas="2600:1901:xxxx:xxxx::xxxx" \
  --ttl=300

# Add A record for backend
gcloud dns record-sets create api.example.com \
  --zone=$ZONE_NAME \
  --type=A \
  --rrdatas="34.120.yyy.yyy" \
  --ttl=300
```

### Option B: Using External DNS Provider

If using external DNS (e.g., Cloudflare, Route53):

1. Log in to your DNS provider
2. Add A records:
   - `app.example.com` → IP from domain mapping
   - `api.example.com` → IP from domain mapping
3. Add AAAA records (IPv6) if provided
4. Set TTL to 300 seconds (5 minutes)

## Step 5: Verify DNS Propagation

Wait for DNS propagation (can take 5-60 minutes):

```bash
# Check DNS resolution
dig app.example.com
dig api.example.com

# Or use nslookup
nslookup app.example.com
nslookup api.example.com
```

## Step 6: Wait for SSL Certificate

Google automatically provisions SSL certificates. Wait for certificate to be issued:

```bash
# Check domain mapping status
gcloud run domain-mappings describe app.example.com --region=$REGION

# Status should show:
# - Type: Ready, Status: True
# - SSL certificate will be automatically provisioned
```

SSL certificate provisioning typically takes 15-60 minutes after DNS records are correctly configured.

## Step 7: Verify HTTPS Access

Test HTTPS access:

```bash
# Test frontend
curl -I https://app.example.com

# Test backend
curl -I https://api.example.com

# Should return 200 OK with valid SSL certificate
```

## Step 8: Configure CORS (Backend)

If your backend needs to accept requests from frontend domain:

```bash
# Update backend CORS settings
gcloud run services update ${BACKEND_SERVICE} \
  --region=$REGION \
  --update-env-vars="CORS_ORIGIN=https://app.example.com"
```

## Step 9: Update Application URLs

Update your application to use custom domains:

```bash
# Frontend environment variables
gcloud run services update ${FRONTEND_SERVICE} \
  --region=$REGION \
  --update-env-vars="NEXT_PUBLIC_API_URL=https://api.example.com"

# Backend environment variables
gcloud run services update ${BACKEND_SERVICE} \
  --region=$REGION \
  --update-env-vars="FRONTEND_URL=https://app.example.com"
```

## Step 10: Set Up Redirects (Optional)

Redirect `www` to non-www (or vice versa):

```bash
# Create www subdomain mapping
gcloud run domain-mappings create \
  --service=${FRONTEND_SERVICE} \
  --domain=www.example.com \
  --region=$REGION

# Handle redirect in application code or Cloud Load Balancer
```

## Step 11: Configure Custom Headers (Optional)

Add custom headers via Cloud Load Balancer or application:

```bash
# Custom headers are typically handled in application code
# Or via Cloud Load Balancer URL map
```

## Step 12: Set Up Multiple Environments

Map domains for different environments:

```bash
# Development
gcloud run domain-mappings create \
  --service=${FRONTEND_SERVICE}-dev \
  --domain=dev.example.com \
  --region=$REGION

# Staging
gcloud run domain-mappings create \
  --service=${FRONTEND_SERVICE}-staging \
  --domain=staging.example.com \
  --region=$REGION

# Production (already configured)
# app.example.com → ${FRONTEND_SERVICE}-prod
```

## Step 13: Monitor Domain Status

Check domain mapping status:

```bash
# List all domain mappings
gcloud run domain-mappings list --region=$REGION

# Describe specific domain
gcloud run domain-mappings describe app.example.com --region=$REGION

# Check SSL certificate status
gcloud run domain-mappings describe app.example.com --region=$REGION \
  --format="value(status.conditions)"
```

## Verification Checklist

- [ ] Domain mappings created
- [ ] DNS records configured
- [ ] DNS propagation verified
- [ ] SSL certificates issued
- [ ] HTTPS access working
- [ ] CORS configured (if needed)
- [ ] Application URLs updated
- [ ] All environments configured

## Common Issues

### Issue: "DNS records not found"

**Solution**:

1. Verify DNS records are correctly configured
2. Check TTL and wait for propagation
3. Use `dig` or `nslookup` to verify

### Issue: "SSL certificate not issued"

**Solution**:

1. Ensure DNS records are correct and propagated
2. Wait 15-60 minutes for certificate provisioning
3. Check domain mapping status

### Issue: "Certificate expired"

**Solution**:

1. Google-managed certificates auto-renew
2. If manual certificate, renew before expiration
3. Check certificate status in domain mapping

### Issue: "CORS errors"

**Solution**:

1. Verify CORS origin matches frontend domain exactly
2. Check backend CORS configuration
3. Ensure HTTPS is used (not HTTP)

## Best Practices

1. **Use Cloud DNS**: Easier integration with GCP services
2. **Short TTL**: Use 300 seconds for faster updates
3. **HTTPS Only**: Always use HTTPS, redirect HTTP to HTTPS
4. **Subdomain Strategy**: Use subdomains for different services
5. **Environment Separation**: Use different domains for dev/staging/prod
6. **Monitor Status**: Regularly check domain mapping status
7. **DNS Propagation**: Allow time for DNS changes to propagate
8. **SSL Certificates**: Use Google-managed certificates (automatic renewal)

## Security Considerations

1. **HTTPS Enforcement**: Always use HTTPS
2. **HSTS Headers**: Add HSTS headers in application
3. **Certificate Pinning**: Consider certificate pinning for mobile apps
4. **DNS Security**: Use DNSSEC if available
5. **Domain Verification**: Verify domain ownership

## Next Steps

Once domain mapping is configured, proceed to:

- **[09. Connecting Services](./09-connecting-services.md)** - Final integration steps

## Additional Resources

- [Cloud Run Domain Mapping](https://cloud.google.com/run/docs/mapping-custom-domains)
- [Cloud DNS Documentation](https://cloud.google.com/dns/docs)
- [SSL Certificate Management](https://cloud.google.com/load-balancing/docs/ssl-certificates)
