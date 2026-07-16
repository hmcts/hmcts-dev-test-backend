# Dev environment — use with:
#   terraform plan  -var-file=environments/dev.tfvars ...
#   terraform apply -var-file=environments/dev.tfvars ...
# Secrets (db_admin_password, container_image): pass via -var / CI, not here.

environment = "dev"
location    = "uksouth"

# Container sizing
container_cpu    = 0.25
container_memory = "0.5Gi"
min_replicas     = 0
max_replicas     = 2
server_port      = 4000

# Non-secret app env vars — add/remove keys here without editing compute.tf.
# DB_HOST is not set here: derived in locals.tf from the Postgres server FQDN and merged in.
container_env = {
  SERVER_PORT  = "4000"
  DB_PORT      = "5432"
  DB_NAME      = "devtest"
  DB_USER_NAME = "psqladmin"
}

# Secret env vars: ENV_NAME -> Container App secret name (value lives in Key Vault).
container_secret_env = {
  DB_PASSWORD = "db-password"
}

# DB sizing / identity (Postgres resource — keep in sync with container_env DB_* above)
db_name                  = "devtest"
db_admin_username        = "psqladmin"
db_port                  = 5432
db_sku                   = "B_Standard_B1ms"
db_version               = "16"
db_storage_mb            = 32768
db_backup_retention_days = 7

# Globally unique Key Vault name (3–24 chars).
key_vault_name = "kv-devtest-dev-001"
