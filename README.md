# GCP Deployment Blueprint

A production-grade, reusable deployment blueprint for Google Cloud Platform (GCP) projects using Cloud Run, Cloud Build, Vertex AI, Google Cloud Storage, and Domain Mapping.

## 🤖 For AI Agents

**If you're an AI assistant implementing this template**, see **[AGENTS.md](./AGENTS.md)** for:

- Prerequisites checklist
- Questions to ask users
- Step-by-step implementation guide
- Common pitfalls to avoid

## 🎯 Purpose

This blueprint provides a standardized, production-ready infrastructure setup that can be reused across multiple SaaS and AI products. It includes:

- **Architecture documentation** with diagrams and request flows
- **Step-by-step setup guides** for complete GCP configuration
- **CI/CD templates** for automated deployments
- **Infrastructure as Code** (Terraform) for reproducible environments
- **Secrets management** best practices
- **Production-focused** (single prod environment)

## 📁 Structure

```
gcp-deployment-blueprint/
├── README.md                          # This file
├── architecture.md                    # Architecture overview and diagrams
├── setup/
│   ├── 01-project-setup.md           # GCP project creation
│   ├── 02-iam-setup.md               # Service accounts and IAM
│   ├── 03-artifact-registry.md       # Container registry setup
│   ├── 04-cloud-run-setup.md         # Cloud Run services
│   ├── 05-cloud-build-setup.md       # CI/CD triggers
│   ├── 06-vertex-ai-setup.md         # Vertex AI configuration
│   ├── 07-gcs-setup.md                # Cloud Storage buckets
│   ├── 08-domain-mapping.md           # Custom domains and SSL
│   └── 09-connecting-services.md      # Integration guide
├── cicd/
│   ├── cloudbuild.backend.yaml        # Backend deployment template
│   ├── cloudbuild.frontend.yaml       # Frontend deployment template
│   └── README.md                      # CI/CD usage guide
├── terraform/
│   ├── main.tf                        # Main infrastructure
│   ├── variables.tf                   # Variable definitions
│   ├── outputs.tf                     # Output values
│   ├── environments/
│   │   └── prod.tfvars                # Production environment config
│   └── README.md                      # Terraform usage guide
├── secrets/
│   ├── README.md                      # Secrets management guide
│   └── examples/
│       ├── secret-list.yaml           # Example secret definitions
│       └── env-mapping.yaml           # Environment variable mapping
└── examples/
    └── project-config.yaml            # Example project configuration
```

## 🚀 Quick Start

### Prerequisites

- Google Cloud SDK (`gcloud`) installed and authenticated
- Terraform >= 1.5.0 installed
- Docker installed (for local testing)
- Domain name ready for mapping (optional)

### 1. Review Architecture

Start by reading [`architecture.md`](./architecture.md) to understand the system design.

### 2. Follow Setup Guides

Execute the setup guides in order:

```bash
# 1. Create GCP project
# Follow: setup/01-project-setup.md

# 2. Configure IAM
# Follow: setup/02-iam-setup.md

# 3. Set up Artifact Registry
# Follow: setup/03-artifact-registry.md

# ... continue through all setup guides
```

### 3. Deploy Infrastructure

Use Terraform to provision resources:

```bash
cd terraform
terraform init
terraform plan -var-file=environments/dev.tfvars
terraform apply -var-file=environments/dev.tfvars
```

### 4. Configure CI/CD

Copy and customize Cloud Build templates:

```bash
cp cicd/cloudbuild.backend.yaml <your-project>/cloudbuild.yaml
# Customize for your project
```

### 5. Set Up Secrets

Follow the secrets management guide:

```bash
# Read: secrets/README.md
# Create secrets in Secret Manager
```

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        User Browser                          │
└───────────────────────┬─────────────────────────────────────┘
                        │ HTTPS
                        ▼
┌─────────────────────────────────────────────────────────────┐
│              Custom Domain (Cloud DNS)                       │
│              SSL Certificate (Managed)                       │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│              Cloud Load Balancer / Cloud Run                │
│              ┌──────────────┬──────────────┐               │
│              │   Frontend   │   Backend    │               │
│              │  (Cloud Run) │  (Cloud Run) │               │
│              └──────┬───────┴──────┬───────┘               │
└─────────────────────┼──────────────┼───────────────────────┘
                      │              │
        ┌─────────────┘              └─────────────┐
        │                                          │
        ▼                                          ▼
┌───────────────┐                      ┌──────────────────┐
│  Cloud Build  │                      │  Vertex AI       │
│  (CI/CD)      │                      │  (AI Models)     │
└───────────────┘                      └──────────────────┘
        │                                          │
        │                                          │
        ▼                                          ▼
┌───────────────┐                      ┌──────────────────┐
│ Artifact      │                      │  Cloud Storage   │
│ Registry      │                      │  (File Storage)  │
└───────────────┘                      └──────────────────┘
```

For detailed architecture, see [`architecture.md`](./architecture.md).

## 🔧 Customization

### Project-Specific Variables

All templates use variables that should be customized per project:

- **Project ID**: Your GCP project ID
- **Region**: Preferred GCP region (e.g., `us-central1`, `asia-south1`)
- **Service Names**: Frontend/backend service names
- **Domains**: Custom domain names
- **Resource Limits**: CPU, memory, instance counts

### Environment Configuration

The blueprint is configured for **production** environment:

- **prod**: Production environment (high availability, scaling, always-on instances)

Configure in `terraform/environments/prod.tfvars`.

## 🐳 Dockerfile Examples

Production-ready Dockerfiles are included:

- **`examples/Dockerfile.nestjs-standalone`** - For standalone NestJS apps
- **`examples/Dockerfile.nestjs-monorepo`** - For NestJS apps in monorepos (pnpm workspaces)
- **`examples/Dockerfile.nextjs-monorepo`** - For Next.js apps in monorepos (pnpm workspaces)
- **`examples/DOCKERFILE_GUIDE.md`** - Complete guide with customization instructions

**Important**: All monorepo Dockerfiles use `--shamefully-hoist` flag for proper module resolution in Docker, even if your `.npmrc` has `shamefully-hoist=false`.

See the [Dockerfile Guide](examples/DOCKERFILE_GUIDE.md) for detailed usage and customization.

## 📚 Documentation

- **[Architecture](./architecture.md)** - System design and request flows
- **[Setup Guides](./setup/)** - Step-by-step configuration instructions
- **[CI/CD](./cicd/README.md)** - Cloud Build templates and usage
- **[Terraform](./terraform/README.md)** - Infrastructure as Code guide
- **[Secrets](./secrets/README.md)** - Secrets management best practices

## 🔒 Security Best Practices

This blueprint follows GCP security best practices:

- ✅ Service accounts with least privilege
- ✅ Secrets stored in Secret Manager (not in code)
- ✅ IAM roles scoped to specific resources
- ✅ Private Artifact Registry (optional)
- ✅ VPC connector for private networking (optional)
- ✅ Cloud Armor for DDoS protection (optional)

## 🎓 Learning Resources

- [GCP Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Cloud Build Documentation](https://cloud.google.com/build/docs)
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Secret Manager Best Practices](https://cloud.google.com/secret-manager/docs/best-practices)

## 🤝 Contributing

When adapting this blueprint for a new project:

1. Copy the entire `gcp-deployment-blueprint` folder
2. Customize variables in Terraform configs
3. Update Cloud Build templates with your build steps
4. Modify setup guides if your project has unique requirements
5. Document any project-specific changes

## 📝 License

This blueprint is provided as-is for internal use. Customize as needed for your projects.

## 🆘 Troubleshooting

Common issues and solutions:

- **Cloud Build fails**: Check IAM permissions for Cloud Build service account
- **Cloud Run deployment fails**: Verify image exists in Artifact Registry
- **Domain mapping fails**: Ensure DNS records are correctly configured
- **Secrets not accessible**: Check IAM bindings for Secret Manager

For detailed troubleshooting, see individual setup guides.

---

**Created for**: Standardized GCP deployments across SaaS and AI products  
**Last Updated**: 2024  
**Maintained By**: DevOps Team
