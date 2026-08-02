# Infrastructure Monolith: Azure Key Vault, PostgreSQL & Container Apps

This repository provisions an end-to-end cloud environment on Microsoft Azure using Terraform in a **Hardened Single-Directory Architecture**.

## Architecture & Decisions

### Compute Service Choice: Azure Container Apps
**Azure Container Apps (ACA)** was selected over Azure App Service for Containers for the following reasons:
* **Pricing and Serverless Scaling:** Pay per use model. Microservice containers can scale down to zero when idle to minimize costs.
* **Simplified Infrastructure:** Provides native container orchestration capabilities without requiring full AKS management or dedicated App Service Plans.
* **Full usage of compute:** Unlike Azure app service which requires staging slots for Zero downtime deployments, Container apps maximises usage of entire compute power without compromising on zero downtime deployments.
* **Canary releases:** Can run with multiple versions at the same time (Easy to perform sanity/PCT before rolling out).

### Running locally

```bash
terraform init -backend=false

terraform fmt -check -recursive

terraform validate
```
