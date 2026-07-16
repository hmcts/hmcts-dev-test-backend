# Infrastructure — Terraform (Azure)

Defines the production infrastructure for the backend service on Azure using Container Apps and PostgreSQL Flexible Server.

## Resources

| Resource | Name pattern |
|---|---|
| Resource Group | `rg-<service>-<env>` |
| PostgreSQL Flexible Server | `psql-<service>-<env>` |
| PostgreSQL Database | `devtest` |
| Key Vault | `var.key_vault_name` (user-supplied, globally unique) |
| User-Assigned Identity | `id-<service>-<env>` |
| Container Apps Environment | `cae-<service>-<env>` |
| Container App | `ca-<service>-<env>` |

## Why Azure Container Apps?

Container Apps is purpose-built for containerised workloads: it supports native Key Vault secret references (the DB password is fetched by the managed identity at runtime — never stored as a plain env var), scales to zero between requests, and requires no infrastructure management compared to App Service.

## Secret management

The database password flows as follows:

1. CI pipeline supplies `db_admin_password` as a pipeline secret (never committed)
2. Terraform writes it to Key Vault as `db-password`
3. The Container App's user-assigned managed identity has the built-in **Key Vault Secrets User** role on the vault
4. Container Apps fetches the secret at runtime and injects it as `DB_PASSWORD`

Access is granted via Azure RBAC (`enable_rbac_authorization = true`): the deployer gets **Key Vault Secrets Officer**, the app gets **Key Vault Secrets User**.

The app currently connects as the **PostgreSQL administrator** (`db_admin_username` / `db_admin_password`) — there is no separate least-privilege application DB user yet. Acceptable for simple/dev; for production, create an app-only role and keep the admin for ops/migrations.

The password never appears in plain text in the repository, Terraform state is the only place it is stored at rest (see state management below).

## State management

In a real deployment, state is stored remotely in an Azure Storage Account so the whole team shares a single source of truth and concurrent applies are safe via blob-lease locking.

**One-time setup** (run once per environment, outside Terraform):

```bash
az group create --name rg-tfstate --location uksouth
az storage account create --name <unique-name> --resource-group rg-tfstate --sku Standard_LRS
az storage container create --name tfstate --account-name <unique-name>
```

Then uncomment the `backend "azurerm"` block in `main.tf` and fill in the storage account name.

The backend block is currently commented out so `terraform validate` runs locally without Azure credentials.

## CI (plan / apply)

The reusable workflow `.github/workflows/_terraform.yml` runs:

1. `fmt` + `validate` (no Azure credentials)
2. `plan` against remote state (Azure OIDC)
3. `apply` only when called with `apply: true` (main CI does this on `master`)

Required GitHub Actions secrets:

| Secret | Purpose |
|---|---|
| `AZURE_CLIENT_ID` | App registration for OIDC login |
| `AZURE_TENANT_ID` | Azure AD tenant |
| `AZURE_SUBSCRIPTION_ID` | Target subscription |
| `DB_ADMIN_PASSWORD` | Postgres admin + Key Vault secret value |
| `TF_STATE_STORAGE_ACCOUNT` | Storage account for `azurerm` backend |
| `TF_STATE_RESOURCE_GROUP` | Optional (defaults to `rg-tfstate`) |

Configure federated credentials on the Azure app registration for this repo (GitHub OIDC). Override backend `storage_account_name` via the secret — do not commit a real account name if you prefer secrets.

## Environment config (`*.tfvars`)

Per-environment values live under `environments/` (not in `locals.tf`):

| File | Use |
|---|---|
| `environments/dev.tfvars` | Dev sizing / scale-to-zero |
| `environments/prod.tfvars` | Production sizing / retention |

`locals.tf` only holds derived values (resource name patterns, tags, `is_production`).

Secrets (`db_admin_password`, `container_image`) and globally unique `key_vault_name` are passed at apply time — do not commit them in tfvars.

## Running locally

```bash
cd terraform

# Initialise providers (no backend credentials needed)
terraform init -backend=false

# Check formatting
terraform fmt -check -recursive

# Validate configuration
terraform validate

# Preview changes (requires Azure credentials)
terraform plan \
  -var-file=environments/prod.tfvars \
  -var="container_image=ghcr.io/org/repo:<sha>" \
  -var="key_vault_name=kv-devtest-prod-<unique>" \
  -var="db_admin_password=<password>"
```

## Required variables

| Variable | Description |
|---|---|
| `container_image` | Fully-qualified image tag (e.g. `ghcr.io/org/repo:<sha>`) |
| `key_vault_name` | Globally unique Key Vault name (3–24 chars) |
| `db_admin_password` | PostgreSQL admin password — supply via pipeline secret |
