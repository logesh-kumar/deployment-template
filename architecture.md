# GCP Deployment Architecture

This document describes the architecture for deploying SaaS and AI applications on Google Cloud Platform using Cloud Run, Cloud Build, Vertex AI, Google Cloud Storage, and Domain Mapping.

## 🏗️ High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Internet / Users                            │
└───────────────────────────────┬─────────────────────────────────────┘
                                │ HTTPS (Port 443)
                                │ Custom Domain
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    Google Cloud Load Balancer                       │
│                    (Managed SSL Certificates)                       │
│                    ┌─────────────────────────┐                     │
│                    │   Domain Mapping        │                     │
│                    │   - api.example.com     │                     │
│                    │   - app.example.com     │                     │
│                    └───────────┬─────────────┘                     │
└────────────────────────────────┼────────────────────────────────────┘
                                 │
                    ┌────────────┴────────────┐
                    │                        │
                    ▼                        ▼
        ┌───────────────────┐    ┌───────────────────┐
        │   Frontend        │    │   Backend         │
        │   (Cloud Run)     │    │   (Cloud Run)     │
        │                   │    │                   │
        │   - Next.js       │    │   - NestJS        │
        │   - React         │    │   - Express       │
        │   - Static Files  │    │   - API Routes    │
        │                   │    │   - Business Logic│
        └─────────┬─────────┘    └─────────┬─────────┘
                  │                        │
                  │                        │
        ┌─────────┴─────────┐    ┌─────────┴─────────┐
        │                   │    │                   │
        ▼                   ▼    ▼                   ▼
┌───────────────┐  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐
│ Vertex AI     │  │ Cloud Storage │  │ Cloud SQL /   │  │ Secret Manager│
│ (AI Models)   │  │ (Files/Media) │  │ PostgreSQL    │  │ (Secrets)     │
└───────────────┘  └───────────────┘  └───────────────┘  └───────────────┘
        │                   │                │                   │
        └───────────────────┴────────────────┴───────────────────┘
                                │
                                ▼
                    ┌───────────────────────┐
                    │   Cloud Build         │
                    │   (CI/CD Pipeline)    │
                    │                       │
                    │   - Build Images      │
                    │   - Run Tests         │
                    │   - Deploy Services   │
                    └───────────┬───────────┘
                                │
                                ▼
                    ┌───────────────────────┐
                    │   Artifact Registry    │
                    │   (Container Images)  │
                    └───────────────────────┘
```

## 🔄 Request Flow

### Frontend Request Flow

```
1. User → Browser
   └─> Navigates to https://app.example.com

2. Browser → Cloud DNS
   └─> DNS lookup for app.example.com
   └─> Returns Cloud Run service IP

3. Browser → Cloud Load Balancer
   └─> HTTPS request with SSL certificate
   └─> Load balancer terminates SSL

4. Load Balancer → Cloud Run (Frontend)
   └─> Routes to frontend service
   └─> Cloud Run serves static files or SSR

5. Frontend → Backend API (if needed)
   └─> API call to https://api.example.com
   └─> Follows backend request flow (below)
```

### Backend Request Flow

```
1. Frontend → Backend API
   └─> HTTP request to https://api.example.com/endpoint

2. Cloud Load Balancer → Cloud Run (Backend)
   └─> Routes to backend service
   └─> Cloud Run container starts (if cold)

3. Backend → Secret Manager
   └─> Retrieves DATABASE_URL, API keys, etc.
   └─> Secrets injected as environment variables

4. Backend → Cloud SQL / PostgreSQL
   └─> Database query using connection from Secret Manager
   └─> Returns data

5. Backend → Cloud Storage (if needed)
   └─> Upload/download files
   └─> Returns file URLs or content

6. Backend → Vertex AI (if needed)
   └─> AI model inference request
   └─> Returns predictions/results

7. Backend → Frontend
   └─> JSON response with data
   └─> Frontend renders UI
```

### CI/CD Deployment Flow

```
1. Developer → Git Push
   └─> Push code to GitHub/GitLab/Bitbucket

2. Git → Cloud Build Trigger
   └─> Webhook triggers Cloud Build
   └─> Cloud Build service account authenticated

3. Cloud Build → Build Steps
   ├─> Install dependencies
   ├─> Run tests
   ├─> Build Docker image
   └─> Push to Artifact Registry

4. Cloud Build → Cloud Run Deploy
   └─> Deploy new image to Cloud Run
   └─> Update service with new revision
   └─> Traffic gradually shifts to new revision

5. Cloud Run → Health Check
   └─> Verifies new revision is healthy
   └─> Routes 100% traffic to new revision
```

## 🧩 Component Details

### 1. Cloud Run (Frontend & Backend)

**Purpose**: Serverless container platform for running applications

**Features**:

- Auto-scaling (0 to N instances)
- Pay-per-use pricing
- Built-in load balancing
- Automatic HTTPS
- Request timeout handling
- Memory and CPU configuration

**Configuration**:

- **Frontend**:
  - Memory: 512Mi - 1Gi
  - CPU: 1-2 vCPU
  - Min instances: 0 (dev) or 1 (prod)
  - Max instances: 10-100
  - Timeout: 60s

- **Backend**:
  - Memory: 1Gi - 4Gi
  - CPU: 1-4 vCPU
  - Min instances: 0 (dev) or 1 (prod)
  - Max instances: 10-100
  - Timeout: 300s

### 2. Cloud Build (CI/CD)

**Purpose**: Automated build and deployment pipeline

**Features**:

- Source code integration (GitHub, GitLab, Bitbucket)
- Docker image building
- Automated testing
- Deployment to Cloud Run
- Secret management integration

**Build Steps**:

1. Checkout source code
2. Install dependencies
3. Run tests (optional)
4. Build Docker image
5. Push to Artifact Registry
6. Deploy to Cloud Run
7. Update secrets/env vars

### 3. Artifact Registry

**Purpose**: Private container image storage

**Features**:

- Docker image storage
- Version tagging (BUILD_ID, latest)
- Access control via IAM
- Integration with Cloud Run
- Multi-region support

**Image Naming**:

```
<region>-docker.pkg.dev/<project-id>/<repository>/<service>:<tag>
```

### 4. Vertex AI

**Purpose**: AI/ML model hosting and inference

**Features**:

- Pre-trained model APIs
- Custom model deployment
- Batch and online predictions
- AutoML capabilities
- Model versioning

**Integration**:

- Backend calls Vertex AI APIs
- Authentication via service account
- Region-specific endpoints

### 5. Cloud Storage (GCS)

**Purpose**: Object storage for files, media, and static assets

**Features**:

- Unlimited storage
- Multiple storage classes (Standard, Nearline, Coldline)
- Lifecycle policies
- CDN integration (optional)
- Signed URLs for private access

**Bucket Structure**:

```
gs://<project-id>-<environment>-<purpose>/
  ├── uploads/
  ├── media/
  └── static/
```

### 6. Secret Manager

**Purpose**: Secure storage of sensitive configuration

**Features**:

- Encrypted at rest
- Version management
- Access control via IAM
- Automatic rotation (optional)
- Integration with Cloud Run

**Common Secrets**:

- Database connection strings
- API keys
- OAuth credentials
- JWT secrets
- SMTP credentials

### 7. Domain Mapping & SSL

**Purpose**: Custom domain names with automatic SSL

**Features**:

- Custom domain mapping
- Automatic SSL certificate provisioning
- DNS management (Cloud DNS)
- Load balancer integration
- Multiple domains per service

**Setup**:

1. Create domain mapping in Cloud Run
2. Update DNS records (A/CNAME)
3. SSL certificate auto-provisioned
4. HTTPS traffic routed to Cloud Run

## 🔐 Security Architecture

### Authentication & Authorization

```
┌──────────────┐
│   Users      │
└──────┬───────┘
       │
       ▼
┌──────────────────┐      ┌──────────────┐
│  Firebase Auth   │◄─────┤  Frontend    │
│  (or OAuth)      │      │  (Cloud Run)  │
└──────┬───────────┘      └──────┬───────┘
       │                         │
       │ JWT Token               │ API Request + Token
       │                         │
       ▼                         ▼
┌──────────────────┐      ┌──────────────┐
│  Backend         │      │  IAM Roles    │
│  (Cloud Run)     │─────►│  (Service    │
│                  │      │   Accounts)   │
└──────┬───────────┘      └──────────────┘
       │
       │ Service Account
       ▼
┌──────────────────┐
│  GCP Services    │
│  (GCS, Vertex AI)│
└──────────────────┘
```

### Network Security

- **Public Endpoints**: Cloud Run services can be public or private
- **VPC Connector**: Optional private networking between services
- **Cloud Armor**: DDoS protection and WAF rules (optional)
- **Private IP**: Services can use private IPs (VPC required)

### Data Security

- **Encryption at Rest**: All GCP services encrypt data by default
- **Encryption in Transit**: HTTPS/TLS for all external traffic
- **Secret Manager**: Encrypted secrets, never in code or logs
- **IAM Policies**: Least privilege access control

## 📊 Scaling Architecture

### Horizontal Scaling

```
Traffic Increase
      │
      ▼
┌──────────────┐
│ Load Balancer│
└──────┬───────┘
       │
       ├──────────┬──────────┬──────────┐
       ▼          ▼          ▼          ▼
┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐
│Instance │  │Instance │  │Instance │  │Instance │
│   1     │  │   2     │  │   3     │  │   N     │
└─────────┘  └─────────┘  └─────────┘  └─────────┘
```

Cloud Run automatically scales based on:

- Request rate
- CPU utilization
- Memory usage
- Concurrent requests per instance

### Vertical Scaling

Configure per service:

- **CPU**: 1-8 vCPU
- **Memory**: 128Mi - 32Gi
- **Concurrency**: 1-1000 requests per instance

## 🔄 Multi-Environment Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    GCP Project                          │
│                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │    DEV       │  │   STAGING    │  │    PROD      │ │
│  │              │  │              │  │              │ │
│  │  - Cloud Run │  │  - Cloud Run │  │  - Cloud Run │ │
│  │  - GCS       │  │  - GCS       │  │  - GCS       │ │
│  │  - Secrets   │  │  - Secrets   │  │  - Secrets   │ │
│  │              │  │              │  │              │ │
│  │  dev.*.com   │  │  staging.*   │  │  *.com       │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
│                                                         │
│  ┌───────────────────────────────────────────────────┐  │
│  │         Shared Resources                         │  │
│  │  - Artifact Registry                             │  │
│  │  - Cloud Build                                   │  │
│  │  - Vertex AI (shared models)                     │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## 📈 Monitoring & Observability

```
┌──────────────┐
│  Cloud Run   │
│  Services    │
└──────┬───────┘
       │
       ├──────────────┬──────────────┬──────────────┐
       ▼              ▼              ▼              ▼
┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
│  Cloud   │  │  Cloud   │  │  Cloud   │  │  Error   │
│  Logging │  │  Monitor │  │  Trace   │  │ Reporting│
└──────────┘  └──────────┘  └──────────┘  └──────────┘
```

- **Cloud Logging**: Application logs, access logs
- **Cloud Monitor**: Metrics, alerts, dashboards
- **Cloud Trace**: Request tracing across services
- **Error Reporting**: Exception tracking and alerts

## 🎯 Best Practices

1. **Separation of Concerns**: Frontend and backend as separate Cloud Run services
2. **Stateless Services**: No local storage, use Cloud Storage
3. **Health Checks**: Implement `/health` endpoints
4. **Graceful Shutdowns**: Handle SIGTERM signals
5. **Resource Limits**: Set appropriate CPU/memory limits
6. **Cost Optimization**: Use min instances = 0 for dev, 1 for prod
7. **Security**: Always use Secret Manager, never hardcode secrets
8. **Monitoring**: Set up alerts for errors and high latency
9. **Backup**: Regular database backups (Cloud SQL)
10. **Disaster Recovery**: Multi-region deployment for critical services

## 📚 Next Steps

- Read [Setup Guides](./setup/) for step-by-step configuration
- Review [CI/CD Templates](./cicd/) for deployment automation
- Explore [Terraform Infrastructure](./terraform/) for IaC
- Learn about [Secrets Management](./secrets/) best practices
