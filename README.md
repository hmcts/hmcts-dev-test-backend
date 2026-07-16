# HMCTS Dev Test Backend

Backend service for the HMCTS case management system. Built with Spring Boot, PostgreSQL, containerised with Docker, and deployed to Azure via Terraform.

---

## Table of contents

- [Application](#application)
  - [Running locally](#running-locally)
  - [Running with Docker Compose](#running-with-docker-compose)
  - [Available endpoints](#available-endpoints)
- [CI/CD Pipeline](#cicd-pipeline)
  - [Pipeline layout](#pipeline-layout)
  - [Workflow files](#workflow-files)
  - [Branch behaviour](#branch-behaviour)
  - [Real world: GitHub Actions](#real-world-github-actions)
- [Terraform](#terraform)
  - [Overview](#overview)
  - [File structure](#file-structure)
  - [Configuration and variables](#configuration-and-variables)
  - [Tagging](#tagging)
  - [Secret management](#secret-management)
  - [State management](#state-management)
  - [CI/CD workflow (current)](#cicd-workflow-current)
  - [Real world Terraform (given more time)](#real-world-terraform-given-more-time)
  - [Running Terraform locally](#running-terraform-locally)

---

## Application

### Running locally

**Prerequisites:** Java 21, a running PostgreSQL instance.

The quickest way to get PostgreSQL running without installing it:

```bash
docker run -d \
  -e POSTGRES_PASSWORD=localdev \
  -e POSTGRES_DB=devtest \
  -p 5432:5432 \
  postgres:16
```

Then start the application, passing the database connection details as environment variables:

```bash
export DB_HOST=localhost
export DB_PORT=5432
export DB_NAME=devtest
export DB_USER_NAME=postgres
export DB_PASSWORD=localdev

./gradlew bootRun
```

Or build and run the jar directly:

```bash
./gradlew bootJar
java -jar build/libs/test-backend.jar
```

The service starts on port `4000` by default. Override with `SERVER_PORT=<port>`.

### Running with Docker Compose

Docker Compose is the recommended way to run the full stack locally — it starts both the application and PostgreSQL together.

**First time setup:**

```bash
cp .env.example .env
# Edit .env and set your preferred credentials
```

Then:

```bash
docker compose up --build
```

Once both containers are healthy:

```bash
curl http://localhost:4000/health
```

A `{"status":"UP"}` response with a `db` component confirms the application is running and connected to the database.

To stop and remove containers (data is preserved in the `db-data` volume):

```bash
docker compose down
```

To also wipe the database volume:

```bash
docker compose down -v
```

### Available endpoints

| Method | Path | Description |
|---|---|---|
| `GET` | `/` | Root — welcome / liveness check |
| `GET` | `/get-example-case` | Returns an example case |
| `GET` | `/health` | Actuator health — includes database connectivity |
| `GET` | `/info` | Actuator info |
| `GET` | `/swagger-ui/index.html` | OpenAPI UI |
| `GET` | `/v3/api-docs` | Raw OpenAPI spec |

---

## CI/CD Pipeline

### Pipeline layout

The pipeline is split across multiple workflow files to keep each concern modular and independently readable. A single orchestrator (`main.yml`) defines the triggers and wires the jobs together — the individual workflow files contain no trigger rules of their own and are only ever called from `main.yml`.

```
.github/workflows/
  main.yml          ← orchestrator — triggers, job ordering, conditional logic
  _build.yml        ← compile, test, Checkstyle
  _docker.yml       ← build image, Trivy scan, push to registry
  _terraform.yml    ← terraform fmt, validate
  _deploy.yml       ← deploy to Azure (placeholder)
```

The full pipeline flow on a push:

```
push / PR
  ├── changes (detect terraform/** modifications)
  │
  ├── build → docker (build → scan → push) → deploy ──┐
  │                                                     │  deploy waits for both
  └── terraform (only if terraform/** changed) ─────────┘
```

Key ordering guarantees:
- **Tests must pass** before a Docker image is built
- **CRITICAL CVEs block the push** — the image never reaches the registry if the Trivy scan fails
- **Terraform runs before deploy** — infrastructure changes land before the new image rolls out
- **Deploy is master-only** — feature branches build and scan but never publish or deploy

### Workflow files

| File | Runs on | What it does |
|---|---|---|
| `_build.yml` | Every push | `./gradlew check` — compile, unit tests, integration tests, Checkstyle |
| `_docker.yml` | Every push (after build) | Build image → Trivy scan (CRITICAL blocks, HIGH warns) → push on master |
| `_terraform.yml` | Only when `terraform/**` changes | `terraform fmt -check` + `terraform validate` |
| `_deploy.yml` | Master only (after docker + terraform) | Deploy to Azure |

### Branch behaviour

| | Feature branch | Master |
|---|---|---|
| Build & test | ✓ | ✓ |
| Docker build | ✓ | ✓ |
| Trivy scan | ✓ | ✓ |
| Push to registry | — | ✓ |
| Terraform fmt + validate | ✓ (if tf changed) | ✓ (if tf changed) |
| Deploy | — | ✓ |

### Security scan results

Trivy scan findings are uploaded to the **GitHub Security tab** after every pipeline run. To view them:

1. Go to the repository on GitHub
2. Click **Security** → **Code scanning**
3. Filter by branch using the search bar (e.g. `is:open branch:your-branch-name`)
4. Findings are split into two categories — `trivy-critical` and `trivy-high` — visible under the **Tool** filter

Each finding shows the CVE ID, affected package, installed version, fixed version (if available), and severity. CRITICAL findings will have blocked the pipeline run — the image will not have been pushed. HIGH findings appear as warnings and do not block the pipeline but should be reviewed and actioned.

> **Note:** The Security tab and code scanning alerts are available on public repositories. For private repositories they require **GitHub Advanced Security**.

### Real world: GitHub Actions

In this repository the reusable workflows (`_build.yml`, `_docker.yml` etc.) are called internally via `workflow_call`. In a real organisation where the same patterns are used across multiple services, each of these would be extracted into its own **public GitHub Action** in a dedicated repository and referenced like any other action:

```yaml
- uses: org/build-action@v1
- uses: org/docker-action@v1
  with:
    image: ghcr.io/${{ github.repository }}
- uses: org/trivy-action@v1
```

This means a security fix or improvement to the build process propagates to all services the moment they bump the action version — rather than each repo maintaining its own copy. The split into separate files here is a step in that direction: the logic is already isolated and the interface (inputs/outputs) is already defined.

---

## Terraform

Defines the production infrastructure for the backend service on Azure. All resources are grouped under a single resource group and follow a consistent naming and tagging convention.

### Overview

| Resource | Name pattern |
|---|---|
| Resource Group | `rg-<service>-<env>` |
| PostgreSQL Flexible Server | `psql-<service>-<env>` |
| PostgreSQL Database | `devtest` (configurable) |
| Key Vault | `var.key_vault_name` (user-supplied, globally unique) |
| User-Assigned Identity | `id-<service>-<env>` |
| Container Apps Environment | `cae-<service>-<env>` |
| Container App | `ca-<service>-<env>` |

**Why Azure Container Apps?** Purpose-built for containerised workloads: natively integrates with Key Vault (password fetched by managed identity at runtime, never a plain env var), scales to zero between requests, and requires no VM or cluster management.

### File structure

```
terraform/
  main.tf        — provider, resource group, locals, (commented) backend
  variables.tf   — all input variables with type constraints and descriptions
  outputs.tf     — useful outputs (URLs, FQDNs, identity IDs)
  postgres.tf    — PostgreSQL Flexible Server, database, firewall rule
  keyvault.tf    — Key Vault, access policies, db-password secret
  compute.tf     — managed identity, Container Apps environment, Container App
```

### Configuration and variables

Day-to-day operational changes — container image version, replica counts, database SKU, port numbers — are driven entirely through **`*.tfvars` files**. The `.tf` files only need to change when new infrastructure components are added (e.g. adding a Redis cache or a new firewall rule).

```
terraform/environments/
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

Sensitive values (`db_admin_password`, `container_image`) are never committed — they are injected at pipeline runtime via `TF_VAR_*` environment variables sourced from GitHub Actions secrets.

### Tagging

All resources inherit a common baseline tag set from `local.tags` in `main.tf`:

```hcl
locals {
  tags = {
    service     = var.service_name
    environment = var.environment
    managed_by  = "terraform"
  }
}
```

Individual resources can extend this with `merge()` for additional resource-level tags:

```hcl
tags = merge(local.tags, {
  tier          = "data"
  backup_policy = "daily"
})
```

### Secret management

The database password never appears in plain text in the repository or as a plain environment variable in the container:

1. CI holds `db_admin_password` as a GitHub Actions secret
2. Terraform receives it via `TF_VAR_db_admin_password` and writes it to Key Vault
3. The Container App's managed identity has `Get` permission on the vault
4. Container Apps fetches the secret at runtime and injects it as `DB_PASSWORD`

`db_admin_password` is marked `sensitive = true` in `variables.tf` — Terraform redacts it from all plan and apply output.

### State management

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

**One-time bootstrap:**

```bash
az group create --name rg-tfstate --location uksouth
az storage account create --name <unique-name> --resource-group rg-tfstate --sku Standard_LRS --allow-blob-public-access false
az storage container create --name tfstate --account-name <unique-name>
```

### CI/CD workflow (current)

The `_terraform.yml` workflow runs when any file under `terraform/` changes, and always completes before the deploy job starts:

- `terraform fmt -check` — fails fast on formatting issues
- `terraform validate` — validates syntax and configuration without requiring Azure credentials

### Real world Terraform (given more time)

The following describes what a production-grade Terraform CI/CD setup would look like.

#### Pipeline flow

```
Feature branch push (terraform/** changed)
  └── fmt -check
  └── validate
  └── plan ──────────────────────── output printed to job log

                  │
                  ▼

Pull request → master (terraform/** changed)
  └── fmt -check
  └── validate
  └── plan ──────────────────────── plan posted as PR comment
                                     reviewers see exact infra diff before approving
                  │
                  │  PR approved & merged
                  ▼

Merge to master (terraform/** changed)
  └── fmt -check
  └── validate
  └── plan (final pre-apply check)
  └── apply ─────────────────────── infrastructure updated
                  │
                  │  apply succeeded
                  ▼
            deploy (new image rolled out)
```

#### Branch commits

On every push to a feature branch, `terraform plan` would run and print the proposed changes to the job log, giving developers early feedback before opening a PR.

#### Pull requests

When a PR targeting `master` is opened, the plan runs against the target state and the output is **posted as a comment on the PR** so reviewers can see exactly what infrastructure would change before approving. No changes are applied — plan is read-only.

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
      -input=false -no-color 2>&1 | tee plan.txt

- name: Post plan to PR
  uses: actions/github-script@v7
  with:
    script: |
      const fs = require('fs');
      const plan = fs.readFileSync('terraform/plan.txt', 'utf8');
      github.rest.issues.createComment({
        issue_number: context.issue.number,
        owner: context.repo.owner,
        repo: context.repo.repo,
        body: `#### Terraform Plan\n\`\`\`\n${plan}\n\`\`\``
      });
```

#### Merge to master (apply)

Once the PR is approved and merged, `terraform apply` runs automatically, followed by deploy only after apply succeeds:

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

#### Terraform modules

This configuration defines resources directly in the root module, appropriate for a single service. In a real organisation, the repeating pattern of managed identity + Key Vault + Container App would be extracted into **shared Terraform modules** in a dedicated repository, consumed by each service:

```hcl
module "app" {
  source          = "git::https://github.com/org/terraform-modules//container-app?ref=v1.2.0"
  service_name    = var.service_name
  environment     = var.environment
  container_image = var.container_image
  secrets         = { db_password = azurerm_key_vault_secret.db_password.id }
}
```

Security or compliance fixes to the module propagate to all consumers on the next version bump, rather than each service maintaining its own copy.

### Running Terraform locally

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
