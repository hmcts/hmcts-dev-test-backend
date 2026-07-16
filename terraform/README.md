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
service_name      = "dev-test-backend"
environment       = "production"
location          = "uksouth"
key_vault_name    = "kv-devtest-prod-<unique>"
db_sku            = "GP_Standard_D2s_v3"
db_name           = "devtest"
db_admin_username = "psqladmin"
min_replicas      = 1
max_replicas      = 5
container_cpu     = 1.0
container_memory  = "2Gi"
server_port       = 4000
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

Individual resources can extend this with additional resource-level tags where needed:

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

## CI/CD workflow (current)

The pipeline (`.github/workflows/main.yml`) detects changes under `terraform/` and runs the Terraform job only when needed. Critically, **infrastructure changes are always applied before a new container image is deployed** — the deploy job has a `needs` dependency on the terraform job and will not start until it completes successfully.

```
push / PR
  ├── changes (detect terraform/** modifications)
  │
  ├── build  →  docker (build → scan → push)  →  deploy ──┐
  │                                                         │  deploy waits for both
  └── terraform (only if terraform/** changed) ────────────┘
```

Currently, the terraform job runs:

- `terraform fmt -check` — fails fast on formatting issues
- `terraform validate` — validates syntax and configuration without requiring Azure credentials

This is sufficient to catch common errors in CI without needing cloud authentication configured in the pipeline.

---

## Real world Terraform (given more time)

The following describes what a production-grade Terraform CI/CD setup would look like. The primitives are in place — the pipeline already gates deploy on terraform, and the `_terraform.yml` workflow is the right place to extend.

### Pipeline flow

```
Feature branch push (terraform/** changed)
  └── fmt -check
  └── validate
  └── plan ─────────────────────────── output printed to job log

                    │
                    ▼

Pull request → master (terraform/** changed)
  └── fmt -check
  └── validate
  └── plan ─────────────────────────── plan output posted as PR comment
                                        reviewers see exact infra diff before approving
                    │
                    │  PR approved & merged
                    ▼

Merge to master (terraform/** changed)
  └── fmt -check
  └── validate
  └── plan (final pre-apply check)
  └── apply ────────────────────────── infrastructure updated
                    │
                    │  apply succeeded
                    ▼
              deploy (new image rolled out)
```

### Branch commits

On every push to a feature branch where `terraform/` files have changed, `terraform plan` would run and print the proposed changes to the job log. This gives developers early feedback on the infrastructure impact of their changes before opening a PR.

### Pull requests

When a PR targeting `master` is opened or updated, the plan runs against the target state and the output is **posted as a comment on the PR** so reviewers can see exactly what infrastructure would change before approving. No changes are applied at this stage — plan is read-only.

```yaml
- name: Terraform plan
  id: plan
  working-directory: terraform
  env:
    TF_VAR_db_admin_password: ${{ secrets.DB_ADMIN_PASSWORD }}
    TF_VAR_container_image:   ${{ needs.docker.outputs.sha_tag }}
  run: |
    terraform plan \
      -var-file=environments/prod.tfvars \
      -input=false \
      -no-color 2>&1 | tee plan.txt

- name: Post plan to PR
  uses: actions/github-script@v7
  with:
    script: |
      const fs = require('fs');
      const plan = fs.readFileSync('terraform/plan.txt', 'utf8');
      const output = `#### Terraform Plan 📋\n\`\`\`\n${plan}\n\`\`\``;
      github.rest.issues.createComment({
        issue_number: context.issue.number,
        owner: context.repo.owner,
        repo: context.repo.repo,
        body: output
      });
```

### Merge to master (apply)

Once the PR is approved and merged, `terraform apply` runs automatically against master:

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

The deploy job waits for apply to complete successfully before rolling out the new container image — ensuring infrastructure is always in the desired state before the application catches up to it.

### Terraform modules

This configuration defines resources directly in the root module, appropriate for a single service. In a real organisation with multiple services, the repeating pattern of managed identity + Key Vault + Container App would be extracted into **shared Terraform modules** in a dedicated repository. Each service would then consume the module rather than duplicating resource definitions:

```hcl
module "app" {
  source          = "git::https://github.com/org/terraform-modules//container-app?ref=v1.2.0"
  service_name    = var.service_name
  environment     = var.environment
  container_image = var.container_image
  secrets         = { db_password = azurerm_key_vault_secret.db_password.id }
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
