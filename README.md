# HMCTS Dev Test Backend

Spring Boot service for the HMCTS case management system, wired to PostgreSQL and shipped as a container. This repository holds the application, its delivery pipeline and the Terraform that defines its production infrastructure on Azure.

| Area | Where |
| --- | --- |
| Application config | `src/main/resources/application.yaml` |
| Container image | `Dockerfile`, `.dockerignore` |
| Local stack | `docker-compose.yml`, `.env.example` |
| Pipeline | `.github/workflows/`, `.github/actions/terraform` |
| Infrastructure | `infrastructure/terraform/` |

Docker is the only requirement to run the service. JDK 21 and Terraform 1.15 are needed only to run the build or the infrastructure checks directly.

---

## Running locally with Docker Compose

```bash
cp .env.example .env
docker compose up --build
```

Once `docker compose ps` shows both services healthy:

```bash
curl http://localhost:4000/                  # welcome message
curl http://localhost:4000/get-example-case  # sample case JSON
curl http://localhost:4000/health            # includes the database check
```

`/health` reports a `db` component only when the datasource is genuinely connected, so a green response confirms the wiring:

```json
{
  "status": "UP",
  "components": {
    "db": { "status": "UP", "details": { "database": "PostgreSQL", "validationQuery": "isValid()" } }
  }
}
```

Stop the database and call `/health/readiness` to see the failure mode: DOWN with a 503, which is what removes a replica from the load balancer in Azure.

Tear down with `docker compose down`, or `-v` to drop the database volume.

`.env` is git-ignored; `.env.example` is the committed template. No password appears in the repository, the image or `docker-compose.yml`.

### Application changes

The datasource is driven by `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER_NAME`, `DB_PASSWORD` and `DB_OPTIONS`. Health is on the actuator exposure list and probes are enabled, so `/health/liveness` and `/health/readiness` exist separately. `build.gradle` adds `spring-boot-starter-jdbc` and the PostgreSQL driver.

The readiness group is `readinessState,db` rather than just `db`: declaring a group replaces the default, and dropping `readinessState` would leave readiness reporting UP throughout graceful shutdown.

The image is multi-stage, runs as a non-root user, and sizes the heap from the container limit.

---

## CI/CD

`ci.yml` holds the triggers and job graph; each stage is a reusable workflow.

| Job | Defined in | What it does |
| --- | --- | --- |
| **Build and test** | `_build-test.yml` | Checkstyle, then `./gradlew build` for unit and integration tests. Reports uploaded as artefacts. |
| **Terraform checks** | `_terraform-checks.yml` | `fmt -check -recursive`, `init -backend=false`, `validate`, plus a Trivy config scan. |
| **Image build and scan** | `_image.yml` | Builds the image and scans it with Trivy. Publishes on master. |
| **CI gate** | `ci.yml` | Single aggregate check for branch protection. |

`deploy.yml` takes an environment and an image tag. `destroy.yml` tears an environment down; `prd` is not one of its options.

`.github/actions/terraform` is a composite action shared by the checks job and both deploy jobs. It installs the pinned version and runs `init`, with or without the remote backend.

### Feature branch vs master

CI runs on every push to every branch. Feature branches build and scan the image but never push it, so no cloud credentials are exposed to unreviewed code. Publishing is gated on the ref:

```yaml
PUBLISH: ${{ github.ref == 'refs/heads/master' || startsWith(github.ref, 'refs/tags/v') }}
```

Master and `v*.*.*` tags log into Azure with OIDC and push to the registry. There are no long-lived Azure credentials in the repository.

Deployment is a separate workflow, so the permissions that can change production are not attached to every CI run.

### Image tagging

| Tag | When | Purpose |
| --- | --- | --- |
| `sha-<short sha>` | Every build | Immutable, one commit, one artefact. The only tag deployments use. |
| `master` | Default branch | Moving pointer at the tip of master. |
| `1.4.2`, `1.4`, `1` | `v*.*.*` git tag | Marked release with the usual aliases. |
| `latest` | Default branch | Convenience for manual pulls. |

A rollback has to name the exact artefact that was running before, which a moving tag cannot do. `image_tag` has no default in Terraform, so a deployment always names what it is shipping.

### Gates

CRITICAL blocks the pipeline, HIGH warns. A hard block on HIGH means a base image CVE with no available fix stops all delivery, including the security fixes that need to ship; `ignore-unfixed` is on for the same reason. Findings from MEDIUM upwards go to the Security tab either way.

Branch protection on `master` should require the **CI gate** check, a pull request with one approval, branches up to date, and no force pushes. Required reviewers on the `prd` GitHub environment make the Terraform apply pause for a human.

### Repository secrets

| Secret | Used for |
| --- | --- |
| `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` | OIDC federated login |
| `ACR_NAME`, `ACR_LOGIN_SERVER` | Registry push target |
| `TF_STATE_RESOURCE_GROUP`, `TF_STATE_STORAGE_ACCOUNT` | Remote state backend |

---

## Infrastructure

A single root module, one file per resource type.

```
main.tf           terraform block, commented backend, provider, resource group
locals.tf         naming patterns and the container configuration maps
variables.tf      every input, typed and described
database.tf       generated password, PostgreSQL server, database, firewall
keyvault.tf       vault, credential secrets, RBAC grants
compute.tf        managed identity, Container Apps environment, the application
registry.tf       container registry and the AcrPull grant
log_analytics.tf  workspace backing Container Apps logs
outputs.tf        grouped outputs for operators and the deploy job
envs/*.tfvars     per-environment values, selected with -var-file
```

### Environments

One configuration, one state file per environment, selected by `-var-file=envs/<env>.tfvars`. `environment` feeds the resource names and the state key, so `dev` and `prd` never collide.

| | dev | prd |
| --- | --- | --- |
| PostgreSQL | `B_Standard_B1ms`, 32 GB, 7-day backups | `GP_Standard_D2s_v3`, 64 GB, 35-day geo-redundant |
| High availability | off | zone-redundant standby |
| Container | 0.5 vCPU, 1 Gi, 0 to 2 replicas | 1 vCPU, 2 Gi, 2 to 10 replicas |
| Registry | Basic | Standard |
| Log retention | 30 days | 90 days |
| Delete protection | off | on |

Everything an environment sets is a variable; `locals.tf` holds only what is derived from them, such as the resource names and the container configuration maps. Adding an environment is a new tfvars file, not a code change.

`delete_protection_enabled` decides whether an environment can be torn down. It drives Key Vault purge protection and whether the provider purges a soft-deleted vault. With it off, `terraform destroy` removes everything and frees the vault name immediately; with it on, a destroyed vault stays recoverable and its name is reserved for the retention period.

Production is protected by process rather than by a lifecycle rule: `destroy.yml` has no `prd` option, and the apply job waits on the environment's required reviewers. A `prevent_destroy` rule cannot vary by environment, because Terraform requires it to be a literal.

Only the Azure infrastructure is environment-aware. Docker Compose is a single local stack driven by `.env`, and the application itself carries no per-environment configuration.

### Running a deployment

1. Merge to `master`. CI builds, scans and pushes the image, and prints the `sha-` tag in the job summary.
2. **Actions → Deploy → Run workflow.** Choose the environment and paste that tag.
3. `plan` prints the diff to the job summary. `apply` waits for the environment's required reviewers, then applies and runs a smoke test against `/health/readiness`.

To tear down a lower environment, **Actions → Destroy**, choose it and type the name to confirm.

The same thing locally, with Azure credentials and the backend block uncommented:

```bash
cd infrastructure/terraform
terraform init
terraform plan  -var-file=envs/dev.tfvars -var="image_tag=sha-1a2b3c4"
terraform apply -var-file=envs/dev.tfvars -var="image_tag=sha-1a2b3c4"
terraform destroy -var-file=envs/dev.tfvars -var="image_tag=unused"
```

**Why Container Apps** over App Service for Containers, for a stateless HTTP API: request-based autoscaling with a low floor so idle cost tracks usage; revisions and traffic splitting give blue/green and canary with no extra infrastructure; Key Vault secret references and managed-identity registry pulls are first class, so no credential sits in app configuration.

Resources are named `<organization>-<abbreviation>-<service>-<environment>-<location>`:

| Resource | Name |
| --- | --- |
| Resource group | `hmcts-rg-cms-prd-uks` |
| PostgreSQL server | `hmcts-psql-cms-prd-uks` |
| Container App | `hmcts-ca-cms-prd-uks` |
| Key Vault | `hmcts-kv-cms-prd-uks` |
| Container registry | `hmctscrcmsprduks` |

Resource names use `service.formattedName`, which keeps every name inside its Azure limit; the full `service.name` is used for the container inside the app. `var.tags` is applied unchanged to every resource.

### How credentials reach the application

Terraform generates the database password with `random_password` and writes it to Key Vault. The same value sets `administrator_password` on the server in that apply, because Terraform cannot read it back out of the vault at the moment it creates the server.

The Container App declares its secrets as Key Vault references rather than values, resolved at run time by a user-assigned managed identity holding `Key Vault Secrets User`. `DB_USER_NAME` and `DB_PASSWORD` arrive as secret-backed environment variables; `DB_HOST`, `DB_PORT`, `DB_NAME` and `DB_OPTIONS` are plain values.

The identity is user-assigned because a system-assigned one does not exist until the Container App is created, so its RBAC grants could not be in place before the first revision pulls an image and reads its secrets.

No variable is marked `sensitive`, because no secret is an input. A credential reused from elsewhere would be a `sensitive` variable sourced from pipeline secrets.

### Checking the configuration

```bash
cd infrastructure/terraform
terraform init -backend=false
terraform fmt -check -recursive
terraform validate
```

Neither needs an Azure account, which is why both run in CI on every push. `plan` authenticates against Azure, so it lives in the deploy workflow.

### Deploying it in a real environment

State lives in an Azure Storage account. The block is in `main.tf`, commented out so `terraform validate` runs without credentials:

```hcl
backend "azurerm" {
  resource_group_name  = "hmcts-rg-terraform-state-prd-uks"
  storage_account_name = "hmctssttfstateprduks"
  container_name       = "tfstate"
  key                  = "cms/prd.tfstate"
  use_azuread_auth     = true
  use_oidc             = true
}
```

`use_azuread_auth` and `use_oidc` make the backend authenticate as the pipeline's federated identity rather than with a storage account key. The storage account is created once, outside this configuration, and should have blob versioning, soft delete and a resource lock. State is sensitive because it holds the generated password in plain text.

`deploy.yml` runs three jobs: `resolve` works out the image tag and environment, `plan` prints the plan to the job summary, and `apply` waits on the GitHub environment's required reviewers before applying and running a smoke test against `/health/readiness`. The composite action passes the backend values as `-backend-config` flags, so one configuration serves several environments by varying the state `key`. The plan is not uploaded as an artefact, because a saved plan holds every planned attribute in the clear, including the generated password.

---

## Assumptions and trade-offs

**Assumptions**

- The application is stateless. No schema migration tool is included.
- One environment shape parameterised by `environment`, with sizing and delete protection set per environment in `envs/`.
- `master` is the default branch.
- The state storage account and the Entra ID app registration for OIDC are bootstrapped separately.

**Trade-offs**

- **Scope.** The configuration covers the resource group, database, compute and Key Vault, plus the registry and workspace those depend on. Private networking, diagnostic settings and alerting are the next additions for a live service.
- **Public endpoints on the database and vault.** A Container Apps environment without VNet integration has no stable outbound address, and Container Apps is not a Key Vault trusted service, so there is nothing specific to allowlist. RBAC, TLS enforcement and least-privilege roles carry the security in the meantime.
- **Password authentication.** Entra authentication would remove the stored credential entirely, but the datasource expects a username and password.
- **HIGH CVEs warn rather than block.** The alternative stops delivery on findings the team cannot fix.
- **Ubuntu base rather than Alpine.** Around 90 MB of image size traded for reliable multi-architecture builds.
- **Deterministic names with no random suffix.** Predictable names are worth more operationally than guaranteed uniqueness, and a collision is a clear apply-time error.

**With more time**

- Private networking: a VNet-integrated environment, PostgreSQL on private access, private endpoints for the vault and a Premium registry.
- Diagnostic settings and alerting on database availability, replica restarts and storage headroom.
- Flyway or Liquibase for schema migrations, run before the new revision takes traffic.
- Front Door or Application Gateway with WAF in front of the ingress.
- Canary rollout using Container Apps traffic weights rather than the current all-at-once revision switch.
- The SKUs and replica counts are placeholders; real numbers would come from load testing.
