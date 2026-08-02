# HMCTS Dev Test Backend
This will be the backend for the brand new HMCTS case management system. As a potential candidate we are leaving
this in your hands. Please refer to the brief for the complete list of tasks! Complete as much as you can and be
as creative as you want.

You should be able to run `./gradlew build` to start with to ensure it builds successfully. Then from that you
can run the service in IntelliJ (or your IDE of choice) or however you normally would.

There is an example endpoint provided to retrieve an example of a case. You are free to add/remove fields as you
wish.

## Running Locally with Docker Compose

### 1. Environment Setup

Set your database and application environment variables in your terminal:

```bash
export DB_HOST=localhost
export DB_PORT=5432
export DB_NAME=devtest
export DB_USER_NAME=postgres
export DB_PASSWORD=secure_password
export APP_PORT=4000
```

### 2. Start the Application

Open your terminal in the project root directory and run:

docker compose up -d

### 3. Verify Application Health and Endpoints

#### Welcome message
curl http://localhost:4000/

#### Health check (includes PostgreSQL connection status)
curl http://localhost:4000/health

#### Sample case JSON endpoint
curl http://localhost:4000/get-example-case

### 4. Stopping containers cleanly

#### Stop containers and wipe the persistent pgdata volume
docker compose down -v

### 5. Infrastructure setup using real Azure environment

For production deployments, Terraform state should be stored remotely in a centralized, secure location to enable team collaboration, state locking, and encryption at rest.

#### Recommended Configuration:
State can be stored in an Azure Blob Storage container using the `azurerm` backend block (see `providers.tf`):

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "myapp-tfstate-rg"
    storage_account_name = "myapptfstatesa"
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate"
  }
}
```

- **Creation of Storage account in Azure:** State files are stored in an encrypted Azure Blob Storage container (myapptfstatesa/tfstate) with automatic lease locking to ensure safe, concurrent pipeline execution.
- **Keyless OIDC Authentication:** Service Principal creation with federated credentials to secure Azure to GitHub zero trust integration.
- **Automated PR-Driven Deployment:** Pull requests trigger terraform plan and post an interactive Markdown comment on the PR; merging to master automatically runs terraform apply against your Azure Container App, PostgreSQL, and Key Vault resources.
