# AI Agent Implementation Guide

This guide helps AI assistants properly implement the GCP deployment template for new projects.

## 🎯 Purpose

When a user references this deployment template, follow this guide to:
1. **Ask the right questions** about prerequisites and configuration
2. **Verify prerequisites** before proceeding
3. **Implement the template** step-by-step
4. **Customize** for the specific project

## 📋 Prerequisites Checklist

**Before starting, ask the user about:**

### 1. GCP Project Setup
- [ ] **Project ID**: What is the GCP project ID? (e.g., `my-project-123456`)
- [ ] **Billing**: Is billing enabled on the project? (Required for most services)
- [ ] **Region**: Which GCP region? (e.g., `us-central1`, `asia-south1`)
- [ ] **Authentication**: Is the user authenticated? (`gcloud auth login` and `gcloud auth application-default login`)

### 2. Application Details
- [ ] **Backend Framework**: NestJS? Express? Other?
- [ ] **Frontend Framework**: Next.js? React? Other?
- [ ] **Monorepo**: Is this a monorepo? (pnpm/npm/yarn workspaces)
- [ ] **Package Manager**: pnpm? npm? yarn?
- [ ] **Node Version**: Which Node.js version? (e.g., 18, 20)

### 3. Service Names
- [ ] **Backend Service Name**: What should the backend Cloud Run service be called? (e.g., `my-api`, `backend-service`)
- [ ] **Frontend Service Name**: What should the frontend Cloud Run service be called? (e.g., `my-app`, `frontend-service`)

### 4. Database
- [ ] **Database Type**: PostgreSQL? MySQL? Other?
- [ ] **Database Provider**: Cloud SQL? Neon? Supabase? Other?
- [ ] **Database URL**: Is the connection string available? (Will be stored in Secret Manager)

### 5. Secrets & Configuration
- [ ] **Required Secrets**: What secrets are needed? (e.g., DATABASE_URL, JWT_SECRET, API_KEYS)
- [ ] **Payment Gateway**: Razorpay? Stripe? Other? (or none)
- [ ] **OAuth Provider**: Google? GitHub? Other? (or none)
- [ ] **SMTP**: Email service configured? (or none)

### 6. Domains (Optional)
- [ ] **Custom Domains**: Will custom domains be used? (e.g., `api.example.com`, `app.example.com`)
- [ ] **Domain Names**: What are the domain names?

## 🔍 Verification Steps

**Before proceeding, verify:**

```bash
# 1. Check GCP authentication
gcloud auth list
gcloud auth application-default login

# 2. Check project is set
gcloud config get-value project

# 3. Check billing is enabled
gcloud billing projects describe PROJECT_ID --format="value(billingAccountName)"

# 4. Check required APIs (will be enabled by Terraform, but good to verify)
gcloud services list --enabled --filter="name:cloudbuild.googleapis.com OR name:run.googleapis.com"
```

## 📝 Implementation Steps

### Step 1: Copy Template Files

Copy the following structure to the user's project:

```
project-root/
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── environments/
│   │   └── prod.tfvars
│   └── README.md
├── cicd/
│   ├── cloudbuild.backend.yaml
│   ├── cloudbuild.frontend.yaml
│   └── README.md
├── .dockerignore
└── examples/ (optional - for reference)
```

### Step 2: Customize Terraform Variables

**Update `terraform/environments/prod.tfvars`:**

```hcl
project_id  = "USER_PROJECT_ID"  # Ask user
region      = "us-central1"      # Ask user
environment = "prod"

# Service Names (Ask user)
frontend_service_name = "USER_FRONTEND_NAME"
backend_service_name  = "USER_BACKEND_NAME"

# Resource Configuration (Ask user or use defaults)
frontend_cpu          = "1"
frontend_memory       = "512Mi"
frontend_min_instances = 1
frontend_max_instances = 50
frontend_timeout      = "60"

backend_cpu          = "1"
backend_memory       = "512Mi"
backend_min_instances = 1
backend_max_instances = 100
backend_timeout      = "300"

# Secrets (Ask user - update with actual secret names)
backend_secrets = {
  DATABASE_URL = {
    secret_name = "database-url"
    version     = "latest"
  }
  # Add more secrets based on user's requirements
}

# URLs (Will be set after first deployment)
api_url      = ""
frontend_url = ""
```

### Step 3: Create Dockerfile

**For NestJS Backend:**

- If **standalone**: Copy `examples/Dockerfile.nestjs-standalone` to project root as `Dockerfile`
- If **monorepo**: Copy `examples/Dockerfile.nestjs-monorepo` to `api/Dockerfile` (or appropriate path)

**Customize:**
- Update Node version if needed
- Update build command if different
- Update entry point if different (`dist/main.js` vs `dist/server.js`)
- Update package manager if not using pnpm

### Step 4: Update Cloud Build Configs

**Update `cicd/cloudbuild.backend.yaml`:**

```yaml
substitutions:
  _SERVICE_NAME: "USER_BACKEND_NAME"  # Ask user
  _REGION: "us-central1"               # Ask user
  _ENV: "prod"
  _DOCKERFILE_PATH: "api/Dockerfile"   # Update based on project structure
  _BUILD_CONTEXT: "."

# Update secrets list based on user's requirements
- "--update-secrets"
- "DATABASE_URL=database-url:latest,JWT_SECRET=jwt-secret:latest,..."
```

**Update `cicd/cloudbuild.frontend.yaml`:**

```yaml
substitutions:
  _SERVICE_NAME: "USER_FRONTEND_NAME"  # Ask user
  _REGION: "us-central1"               # Ask user
  _ENV: "prod"
  _DOCKERFILE_PATH: "web/Dockerfile"   # Update based on project structure
  _BUILD_CONTEXT: "."
  _API_URL: ""  # Will be set after backend deployment
```

### Step 5: Create Secrets Setup Script

**Create `scripts/set-secrets-from-env.sh`:**

Ask the user:
- Where are their environment variables stored? (`.env.production`, `.env`, etc.)
- What secrets do they need?

Create a script that reads from their env file and creates secrets in Secret Manager.

### Step 6: Update .dockerignore

Ensure `.dockerignore` excludes:
- `node_modules`
- `dist`, `.next`
- `.git`
- `terraform`
- `cicd`
- Documentation files
- Development files

## ❓ Questions to Ask User

### Before Starting Implementation

1. **"What is your GCP project ID?"**
   - Verify it exists and user has access

2. **"Is billing enabled on this project?"**
   - If no, guide them to enable it

3. **"What GCP region do you want to deploy to?"**
   - Common: `us-central1`, `us-east1`, `asia-south1`, `europe-west1`

4. **"What are your backend and frontend service names?"**
   - Examples: `my-api`, `backend-service`, `api`

5. **"Is this a monorepo or standalone project?"**
   - Affects Dockerfile choice and Cloud Build config

6. **"What package manager are you using?"**
   - pnpm, npm, or yarn (affects Dockerfile and Cloud Build)

7. **"What secrets do you need?"**
   - List: DATABASE_URL, JWT_SECRET, API_KEYS, etc.
   - Ask about payment gateway, OAuth, SMTP

8. **"Where are your environment variables stored?"**
   - `.env.production`, `.env`, etc.

9. **"Do you have a Dockerfile already?"**
   - If yes, review it for Cloud Run compatibility
   - If no, use the template examples

10. **"What Node.js version are you using?"**
    - Update Dockerfile base image accordingly

### During Implementation

- **"Do you want custom domains?"** (Optional)
- **"What are your resource requirements?"** (CPU, memory, scaling)
- **"Do you need any special Cloud Build steps?"** (tests, migrations, etc.)

## ⚠️ Common Pitfalls to Avoid

1. **PORT Environment Variable**
   - ❌ Don't set PORT in Dockerfile or Cloud Build
   - ✅ Cloud Run sets it automatically
   - ✅ App should read from `process.env.PORT`

2. **Image Tagging**
   - ❌ Don't use `$SHORT_SHA` (only works in git-triggered builds)
   - ✅ Use `$BUILD_ID` (works for both manual and git-triggered)

3. **Timeout Format**
   - ❌ Don't use integer: `timeout = 300`
   - ✅ Use string with suffix: `timeout = "300s"`

4. **Secrets**
   - ❌ Don't hardcode secrets in code or configs
   - ✅ Use Secret Manager for all secrets
   - ✅ Grant Cloud Run service account access

5. **Monorepo Builds**
   - ❌ Don't forget to build shared packages first
   - ✅ Build shared → build app → build Docker image

6. **Dependencies**
   - ❌ Don't forget to install dependencies before building
   - ✅ Run `pnpm install` or `npm install` before build

## 🔄 Implementation Workflow

### Phase 1: Prerequisites & Setup
1. Ask all prerequisite questions
2. Verify GCP setup (auth, billing, project)
3. Copy template files to project

### Phase 2: Configuration
1. Update Terraform variables (`prod.tfvars`)
2. Create/update Dockerfile
3. Update Cloud Build configs
4. Create secrets setup script

### Phase 3: Infrastructure
1. Initialize Terraform: `terraform init`
2. Plan: `terraform plan -var-file=environments/prod.tfvars`
3. Apply: `terraform apply -var-file=environments/prod.tfvars`
4. Verify outputs

### Phase 4: Secrets
1. Create secrets: `./scripts/setup-secrets.sh`
2. Set values: `./scripts/set-secrets-from-env.sh .env.production`
3. Verify secrets exist

### Phase 5: Deployment
1. Deploy backend: `gcloud builds submit --config=cicd/cloudbuild.backend.yaml ...`
2. Get backend URL
3. Update frontend config with backend URL
4. Deploy frontend: `gcloud builds submit --config=cicd/cloudbuild.frontend.yaml ...`
5. Update Terraform with service URLs
6. Apply Terraform again

## 📚 Reference Files

When implementing, reference these files:

- **`terraform/main.tf`** - Infrastructure definition
- **`terraform/variables.tf`** - All available variables
- **`terraform/environments/prod.tfvars`** - Configuration template
- **`cicd/cloudbuild.backend.yaml`** - Backend deployment template
- **`cicd/cloudbuild.frontend.yaml`** - Frontend deployment template
- **`examples/Dockerfile.nestjs-standalone`** - Standalone NestJS Dockerfile
- **`examples/Dockerfile.nestjs-monorepo`** - Monorepo NestJS Dockerfile
- **`examples/DOCKERFILE_GUIDE.md`** - Dockerfile customization guide

## ✅ Success Criteria

Implementation is complete when:

- [ ] Terraform infrastructure deployed successfully
- [ ] All secrets created in Secret Manager
- [ ] Backend Docker image builds successfully
- [ ] Backend deployed to Cloud Run
- [ ] Frontend Docker image builds successfully
- [ ] Frontend deployed to Cloud Run
- [ ] Services are accessible via their URLs
- [ ] Health checks pass
- [ ] Documentation updated with project-specific details

## 🆘 Troubleshooting Guide

### If Terraform fails:
- Check billing is enabled
- Verify authentication: `gcloud auth application-default login`
- Check API enablement (Terraform will enable them, but verify permissions)

### If Cloud Build fails:
- Check Dockerfile builds locally first
- Verify image tagging uses `$BUILD_ID`
- Check PORT is not set in env vars
- Verify dependencies are installed before build

### If Cloud Run fails:
- Check logs: `gcloud run services logs read SERVICE_NAME --region=REGION`
- Verify secrets are accessible
- Check PORT is read from environment
- Verify health check endpoint exists

## 📝 Notes for AI Agents

- **Always ask questions** before making assumptions
- **Verify prerequisites** before proceeding
- **Test locally** when possible (Docker builds)
- **Use the template files** as-is, then customize
- **Document changes** made to the template
- **Follow the order** of implementation steps
- **Verify each step** before moving to the next

## 🎓 Example Conversation Flow

```
AI: "I'll help you implement the GCP deployment template. First, let me ask a few questions:

1. What is your GCP project ID?
2. Is billing enabled on this project?
3. What GCP region do you want to deploy to?
4. Is this a monorepo or standalone project?
5. What are your backend and frontend service names?
..."

User: [Answers questions]

AI: "Great! Let me verify your GCP setup..."
[Run verification commands]

AI: "Perfect! Now I'll copy the template files and customize them for your project..."
[Copy and customize files]

AI: "I've set up the infrastructure. Next, let's deploy it..."
[Guide through deployment]
```

---

**Remember**: Always verify prerequisites, ask clarifying questions, and test each step before proceeding to the next.

