# Infrastructure — Terraform (Azure)

Defines the production infrastructure for the backend service on Azure. All resources are grouped under a single resource group and follow a consistent naming and tagging convention.

---

## Overview

| Resource | Name pattern |
|---|---|
| Resource Group | `rg-<service>-<env>` |
| PostgreSQL Flexible Server | `psql-<service>-<env>` |
| PostgreSQL Database | `devtest` (configurable) |
| Key Vault | `var.key_vault_name` (user-supplied, globally unique) |
| User-Assigned Identity | `id-<service>-<env>` |
| Container Apps Environment | `cae-<service>-<env>` |
| Container App | `ca-<service>-<env>` |

### Why Azure Container Apps?

Container Apps is purpose-built for containerised workloads: it natively integrates with Key Vault so the database password is fetched by the managed identity at runtime and never stored as a plain environment variable. It scales to zero between requests (cost-efficient for variable traffic) and requires no VM or cluster management compared to AKS or App Service.

---

## File structure

```
terraform/
  main.tf        — provider, resource group, locals, (commented) backend
  variables.tf   — all input variables with type constraints and descriptions
  outputs.tf     — useful outputs (URLs, FQDNs, identity IDs)
  postgres.tf    — PostgreSQL Flexible Server, database, firewall rule
  keyvault.tf    — Key Vault, access policies, db-password secret
  compute.tf     — managed identity, Container Apps environment, Container App
```

---

## Configuration and variables

Day-to-day operational changes — container image version, replica counts, database SKU, port numbers — are driven entirely through **`*.tfvars` files**. The `.tf` files themselves only need to change when new infrastructure components are added (e.g. adding a Redis cache, a new firewall rule, or a storage account).

This separation means most changes go through a tfvars PR review rather than touching Terraform resource definitions:

```
environments/
  dev.tfvars    — smaller SKUs, scale-to-zero, shorter backup retention
  prod.tfvars   — production SKUs, min replicas, full backup retention
```

Example `prod.tfvars`:

```hcl
service_name     = "dev-test-backend"
environment      = "production"
location         = "uksouth"
key_vault_name   = "kv-devtest-prod-<unique>"
db_sku           = "GP_Standard_D2s_v3"
db_name          = "devtest"
db_admin_username = "psqladmin"
min_replicas     = 1
max_replicas     = 5
container_cpu    = 1.0
container_memory = "2Gi"
server_port      = 4000
```

Sensitive values (`db_admin_password`, `container_image`) are never committed to tfvars — they are injected at pipeline runtime via `TF_VAR_*` environment variables sourced from GitHub Actions secrets.

---

## Tagging

All resources inherit a common baseline tag set defined in `locals` in `main.tf`:

```hcl
locals {
  tags = {
    service     = var.service_name
    environment = var.environment
    managed_by  = "terraform"
  }
}
```

Individual resources can extend this with additional resource-level tags where needed, for example:

```hcl
resource "azurerm_postgresql_flexible_server" "main" {
  ...
  tags = merge(local.tags, {
    tier          = "data"
    backup_policy = "daily"
  })
}
```

This ensures every resource is always tagged with the baseline while still allowing per-resource annotations for cost allocation, compliance, or operational tooling.

---

## Secret management

The database password never appears in plain text in the repository or as a plain environment variable in the container. The flow is:

1. CI pipeline holds `db_admin_password` as a GitHub Actions secret
2. Terraform receives it via `TF_VAR_db_admin_password` and writes it to Key Vault as `db-password`
3. The Container App's user-assigned managed identity has `Get` permission on the vault
4. Container Apps fetches the secret at runtime and injects it as `DB_PASSWORD`

`db_admin_password` is marked `sensitive = true` in `variables.tf` — Terraform redacts it from all plan and apply output. Terraform state is the only place it is stored at rest; the state file itself should be protected (see state management below).

---

## State management

Remote state is stored in Azure Blob Storage so the team shares a single source of truth and concurrent applies are safe via blob-lease locking.

The backend block in `main.tf` is currently commented out so `terraform validate` runs locally without credentials. Uncomment and populate it before the first real apply:

```hcl
backend "azurerm" {
  resource_group_name  = "rg-tfstate"
  storage_account_name = "<globally-unique-storage-account>"
  container_name       = "tfstate"
  key                  = "dev-test-backend/production.tfstate"
}
```

**One-time bootstrap** (run once per environment before first apply):

```bash
az group create --name rg-tfstate --location uksouth
az storage account create --name <unique-name> --resource-group rg-tfstate --sku Standard_LRS --allow-blob-public-access false
az storage container create --name tfstate --account-name <unique-name>
```

The state storage account should have soft delete and versioning enabled so accidental state corruption can be recovered.

---

## CI/CD workflow

The pipeline (`.github/workflows/main.yml`) is structured so that **infrastructure changes are always applied before a new container image is deployed**. If `terraform/` files change in the same commit as application code, Terraform runs first and the deploy job waits for it to complete successfully.

```
push / PR
  ├── changes (detect terraform/** modifications)
  │
  ├── build  →  docker (build → scan → push)  →  deploy ──┐
  │                                                         │  deploy waits for both
  └── terraform (only if terraform/** changed) ────────────┘
```

### Branch commits

On every push to any branch where `terraform/` files have changed, the pipeline runs:

```yaml
- terraform fmt -check    # fails fast on formatting issues
- terraform validate      # validates syntax and config without cloud credentials
- terraform plan          # previews what would change (requires Azure credentials)
```

The plan output is printed to the job log so developers can see the impact of their changes before opening a PR.

### Pull requests

When a PR is raised against `master`, the plan runs again against the target state and the output is **posted as a comment on the PR** so reviewers can see exactly what infrastructure will change before approving. This is typically implemented with a step like:

```yaml
- name: Post plan to PR
  uses: actions/github-script@v7
  with:
    script: |
      const output = `#### Terraform Plan\n\`\`\`\n${{ steps.plan.outputs.stdout }}\n\`\`\``;
      github.rest.issues.createComment({
        issue_number: context.issue.number,
        owner: context.repo.owner,
        repo: context.repo.repo,
        body: output
      });
```

No infrastructure changes are applied at this stage — the plan is read-only and safe to run on every commit.

### Merge to master (apply)

Once the PR is reviewed and approved, merging to `master` triggers `terraform apply` automatically:

```yaml
- name: Terraform apply
  if: github.ref == 'refs/heads/master'
  working-directory: terraform
  env:
    TF_VAR_db_admin_password: ${{ secrets.DB_ADMIN_PASSWORD }}
    TF_VAR_container_image:   ${{ needs.docker.outputs.sha_tag }}
  run: |
    terraform apply -auto-approve \
      -var-file=environments/prod.tfvars \
      -input=false
```

The deploy job (`_deploy.yml`) has a `needs` dependency on the terraform job and only proceeds once apply has completed successfully — ensuring the infrastructure is in the desired state before the new container image is rolled out.

---

## Terraform modules (real-world consideration)

This configuration defines resources directly in the root module, which is appropriate for a single service. In a real organisation with multiple services, the repeating pattern of:

- User-assigned identity
- Key Vault + access policies
- Container Apps environment + Container App

would be extracted into **shared Terraform modules** (e.g. in a `terraform-modules` repository). Each service would then consume the module with a few lines rather than duplicating the full resource definitions:

```hcl
module "app" {
  source         = "git::https://github.com/org/terraform-modules//container-app?ref=v1.2.0"
  service_name   = var.service_name
  environment    = var.environment
  container_image = var.container_image
  secrets        = { db_password = azurerm_key_vault_secret.db_password.id }
}
```

This enforces consistency across services, reduces copy-paste drift, and means security or compliance fixes to the module propagate to all consumers on the next version bump.

---

## Running locally

```bash
cd terraform

# Initialise providers — no backend credentials needed
terraform init -backend=false

# Check formatting
terraform fmt -check -recursive

# Validate configuration
terraform validate

# Preview changes (requires Azure credentials)
terraform plan \
  -var-file=environments/prod.tfvars \
  -var="container_image=ghcr.io/org/repo:<sha>" \
  -var="db_admin_password=<password>"
```
