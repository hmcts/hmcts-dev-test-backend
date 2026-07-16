variable "service_name" {
  type        = string
  description = "Short name for the service, used in resource naming."
  default     = "dev-test-backend"
}

variable "environment" {
  type        = string
  description = "Deployment environment (e.g. production, staging)."
  default     = "production"
}

variable "location" {
  type        = string
  description = "Azure region to deploy resources into."
  default     = "uksouth"
}

variable "key_vault_name" {
  type        = string
  description = "Globally unique Key Vault name (3-24 alphanumeric characters and hyphens). Must be unique across all Azure tenants."
}

variable "db_admin_username" {
  type        = string
  description = "Administrator username for the PostgreSQL Flexible Server. Override per env in environments/*.tfvars."
  default     = "psqladmin"
}

variable "db_admin_password" {
  type        = string
  description = "Administrator password for the PostgreSQL Flexible Server. Mark as sensitive; supply via pipeline secret — never hardcode."
  sensitive   = true
}

variable "db_name" {
  type        = string
  description = "Name of the application database created on the PostgreSQL server. Override per env in environments/*.tfvars."
  default     = "devtest"
}

variable "db_port" {
  type        = number
  description = "PostgreSQL port exposed to the app (usually 5432). Override per env in environments/*.tfvars if needed."
  default     = 5432
}

variable "db_sku" {
  type        = string
  description = "SKU for the PostgreSQL Flexible Server (e.g. B_Standard_B1ms for dev, GP_Standard_D2s_v3 for production)."
  default     = "B_Standard_B1ms"
}

variable "db_version" {
  type        = string
  description = "PostgreSQL major version for the Flexible Server (e.g. 16)."
  default     = "16"
}

variable "db_storage_mb" {
  type        = number
  description = "Allocated storage for the PostgreSQL Flexible Server in MB (e.g. 32768 = 32 GiB)."
  default     = 32768
}

variable "db_backup_retention_days" {
  type        = number
  description = "How many days of automated backups to retain (1–35)."
  default     = 7
}

variable "container_image" {
  type        = string
  description = "Fully-qualified container image reference including tag (e.g. ghcr.io/org/repo:<sha>)."
}

variable "server_port" {
  type        = number
  description = "Port the application listens on inside the container (ingress target_port). Prefer matching SERVER_PORT in container_env."
  default     = 4000
}

variable "container_env" {
  type        = map(string)
  description = "Non-secret container env vars. Add/remove keys in environments/*.tfvars without editing .tf files. DB_HOST is derived in locals from Postgres and merged in."
}

variable "container_secret_env" {
  type        = map(string)
  description = "Secret container env vars: map of ENV_NAME -> Container App secret name. Values stay in Key Vault; only the reference name is configured here."
  default = {
    DB_PASSWORD = "db-password"
  }
}

variable "container_cpu" {
  type        = number
  description = "CPU allocation for the container (in cores). Override per env in environments/*.tfvars."
  default     = 0.5
}

variable "container_memory" {
  type        = string
  description = "Memory allocation for the container (e.g. 1Gi). Override per env in environments/*.tfvars."
  default     = "1Gi"
}

variable "min_replicas" {
  type        = number
  description = "Minimum number of container replicas. Set to 0 to enable scale-to-zero."
  default     = 1
}

variable "max_replicas" {
  type        = number
  description = "Maximum number of container replicas."
  default     = 3
}
