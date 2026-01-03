# Changelog

## [Unreleased] - 2025-01-03

### Fixed
- **Removed deprecated APIs**: Removed `errorreporting.googleapis.com` (deprecated) and `dns.googleapis.com` (optional, requires billing) from required APIs
- **Fixed Cloud Run v2 timeout format**: Changed timeout from integer to string with "s" suffix (e.g., `"300s"` instead of `300`) to match Cloud Run v2 API requirements
- **Removed PORT environment variable**: Cloud Run automatically sets PORT, so it should not be set manually in Terraform or Cloud Build configs
- **Added placeholder images**: Cloud Run services now use `gcr.io/cloudrun/hello` as placeholder so Terraform can create services before Docker images exist
- **Added lifecycle ignore_changes**: Cloud Run services now ignore image changes so Cloud Build can update images without Terraform reverting them
- **Fixed port configuration**: Added required `name = "http1"` to port configuration for Cloud Run v2
- **Fixed Cloud Build image tagging**: Changed from `$SHORT_SHA` to `$BUILD_ID` for compatibility with manual builds (not just git-triggered)
- **Removed timeout from Cloud Build options**: Timeout option is not supported in Cloud Build options section
- **Added .dockerignore**: Created `.dockerignore` file to exclude unnecessary files from Docker builds
- **Simplified to single environment**: Removed dev/staging environments, template now uses prod only
- **Added NestJS Dockerfile examples**: Created production-ready Dockerfiles for standalone and monorepo NestJS apps

### Changed
- Cloud Run services are now created with placeholder images and updated by Cloud Build deployments
- Timeout values must be strings with "s" suffix (e.g., `"300s"`)
- Cloud Build templates now use `$BUILD_ID` instead of `$SHORT_SHA` for image tags (works for both manual and git-triggered builds)
- PORT environment variable removed from Cloud Build configs (Cloud Run sets it automatically)
- Template simplified to production-only environment (removed dev/staging)
- Scaling configuration simplified (no conditional logic)

### Migration Notes
- If you have existing deployments, update your `timeout` variables to include the "s" suffix
- Remove any `PORT` environment variables from your Cloud Run service configurations and Cloud Build configs
- The placeholder image approach allows infrastructure to be created before application images exist
- Update Cloud Build configs to use `$BUILD_ID` instead of `${SHORT_SHA}` or `${_COMMIT_SHA}`

