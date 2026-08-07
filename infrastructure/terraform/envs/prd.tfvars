environment = "prd"

tags = {
  organization = "hmcts"
  service      = "case management system"
  environment  = "prd"
  location     = "uksouth"
  cost_centre  = "dts-devops"
  deployed_by  = "dts-platform-operations"
  managed_by   = "terraform"
}

delete_protection_enabled = true

postgres_sku_name                     = "GP_Standard_D2s_v3"
postgres_storage_mb                   = 65536
postgres_backup_retention_days        = 35
postgres_geo_redundant_backup_enabled = true
postgres_high_availability_enabled    = true

key_vault_sku = "standard"
registry_sku  = "Standard"

container_cpu                 = 1.0
container_memory              = "2Gi"
container_concurrent_requests = 50
min_replicas                  = 2
max_replicas                  = 10

log_retention_days = 90
