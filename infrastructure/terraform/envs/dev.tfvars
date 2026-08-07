environment = "dev"

tags = {
  organization = "hmcts"
  service      = "case management system"
  environment  = "dev"
  location     = "uksouth"
  cost_centre  = "dts-devops"
  deployed_by  = "dts-platform-operations"
  managed_by   = "terraform"
}

# Nothing is retained, so the environment can be destroyed and rebuilt.
delete_protection_enabled = false

postgres_sku_name                     = "B_Standard_B1ms"
postgres_storage_mb                   = 32768
postgres_backup_retention_days        = 7
postgres_geo_redundant_backup_enabled = false
postgres_high_availability_enabled    = false

key_vault_sku = "standard"
registry_sku  = "Basic"

container_cpu                 = 0.5
container_memory              = "1Gi"
container_concurrent_requests = 50
min_replicas                  = 0
max_replicas                  = 2

log_retention_days = 30
