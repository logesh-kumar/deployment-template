# Dockerfile Guide for NestJS Backends

This guide provides production-ready Dockerfiles for deploying NestJS applications to Cloud Run.

**Note**: These Dockerfiles use Node.js 24 and follow proven patterns from working production deployments.

## 📁 Available Examples

### 1. Standalone NestJS Application
**File**: `examples/Dockerfile.nestjs-standalone`

Use this if your NestJS app is **not** in a monorepo (single package).

**Project Structure**:
```
my-api/
  package.json
  pnpm-lock.yaml (or package-lock.json)
  src/
    main.ts
  dist/ (after build)
```

**Usage**:
```bash
# Build
docker build -f examples/Dockerfile.nestjs-standalone -t my-api:latest .

# Test locally
docker run -p 3000:3000 my-api:latest
```

### 2. Monorepo NestJS Application (pnpm workspaces)
**File**: `examples/Dockerfile.nestjs-monorepo`

Use this if your NestJS app is in a **monorepo** with shared packages.

**Project Structure**:
```
my-monorepo/
  package.json (root)
  pnpm-workspace.yaml
  pnpm-lock.yaml
  shared/
    package.json
    src/
    dist/ (after build)
  api/ (or backend/)
    package.json
    src/
    dist/ (after build)
```

**Usage**:
```bash
# Build from monorepo root
docker build -f examples/Dockerfile.nestjs-monorepo -t my-api:latest .

# Or copy to your project
cp examples/Dockerfile.nestjs-monorepo api/Dockerfile
docker build -f api/Dockerfile -t my-api:latest .
```

## 🔧 Customization

### Update Package Manager

If you use `npm` instead of `pnpm`:

```dockerfile
# Replace pnpm installation
RUN npm install -g npm@latest

# Replace pnpm commands
RUN npm ci --frozen-lockfile
RUN npm ci --frozen-lockfile --only=production
```

### Update Node Version

```dockerfile
# Change Node version (default is Node.js 24)
FROM node:24-alpine AS base  # or node:20-alpine, node:22-alpine, etc.
```

### Update Build Command

If your build script is different:

```dockerfile
# In build stage
RUN pnpm build  # or npm run build, yarn build, etc.
```

### Update Entry Point

If your main file is different:

```dockerfile
# In CMD
CMD ["node", "dist/main.js"]  # or dist/server.js, dist/index.js, etc.
```

### Add Environment Variables

For build-time variables:

```dockerfile
# In build stage
ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}
```

For runtime variables, use Cloud Run's `--set-env-vars` or Secret Manager.

## ⚠️ Important Notes

### PORT Environment Variable

**DO NOT** set `PORT` in your Dockerfile or Cloud Build config. Cloud Run sets it automatically.

Your NestJS app should read PORT from environment:

```typescript
// In main.ts
const port = process.env.PORT || 3000;
await app.listen(port);
```

### Health Checks

The Dockerfiles include health checks. Make sure your NestJS app has a `/health` endpoint:

```typescript
// In your controller
@Get('health')
health() {
  return { status: 'ok' };
}
```

### Security

- Dockerfiles use single-stage builds (simpler, proven pattern)
- All dependencies included (ensures runtime compatibility)
- Python and build tools included for native modules (bcrypt, etc.)

## 🚀 Cloud Build Integration

### Standalone App

```yaml
# In cloudbuild.backend.yaml
steps:
  - name: "gcr.io/cloud-builders/docker"
    args:
      - "build"
      - "-f"
      - "Dockerfile"  # or path to your Dockerfile
      - "-t"
      - "${_REGION}-docker.pkg.dev/$PROJECT_ID/docker-repo/${_SERVICE_NAME}:$BUILD_ID"
      - "."
```

### Monorepo App

```yaml
# In cloudbuild.backend.yaml
steps:
  - name: "gcr.io/cloud-builders/docker"
    args:
      - "build"
      - "-f"
      - "api/Dockerfile"  # path to Dockerfile in monorepo
      - "-t"
      - "${_REGION}-docker.pkg.dev/$PROJECT_ID/docker-repo/${_SERVICE_NAME}:$BUILD_ID"
      - "."  # build context is monorepo root
```

## 📝 Checklist

Before deploying, ensure:

- [ ] Dockerfile builds successfully locally
- [ ] App reads `PORT` from `process.env.PORT`
- [ ] Health check endpoint exists (`/health`)
- [ ] Production dependencies are correct
- [ ] Build command matches your `package.json` scripts
- [ ] Entry point path is correct (`dist/main.js` or your path)
- [ ] `.dockerignore` excludes unnecessary files

## 🐛 Troubleshooting

### Build fails with "tsc: not found"
- Ensure dev dependencies are installed in build stage
- Check that TypeScript is in `devDependencies`

### App crashes on startup
- Check logs: `gcloud run services logs read SERVICE_NAME --region=REGION`
- Verify PORT is read from environment, not hardcoded
- Ensure all required environment variables are set

### Image too large
- Use multi-stage builds (already included)
- Check `.dockerignore` excludes `node_modules`
- Use `--prod` flag for production dependencies

### Monorepo build fails
- Ensure shared package is built before API package
- Verify `pnpm-workspace.yaml` is correct
- Check that all workspace packages are copied

## 📚 Additional Resources

- [NestJS Deployment](https://docs.nestjs.com/recipes/deployment)
- [Cloud Run Best Practices](https://cloud.google.com/run/docs/tips)
- [Docker Multi-stage Builds](https://docs.docker.com/build/building/multi-stage/)

