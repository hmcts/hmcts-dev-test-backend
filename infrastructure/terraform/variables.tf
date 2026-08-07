variable "organization" {
  description = "Organisation prefix, the first element of every resource name."
  type        = string
  default     = "hmcts"
}

variable "service" {
  description = "Service name, and the abbreviation used where Azure name limits are tight."
  type        = map(string)
  default = {
    name          = "case management system"
    formattedName = "cms"
  }
}

variable "environment" {
  description = "Deployment environment. Expected: dev, tst, stg or prd."
  type        = string
  default     = "prd"
}

variable "location" {
  description = "Azure region. long is the location the provider accepts, short is the naming suffix."
  type        = map(string)
  default = {
    long  = "uksouth"
    short = "uks"
  }
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default = {
    organization = "hmcts"
    service      = "case management system"
    environment  = "prd"
    location     = "uksouth"
    cost_centre  = "dts-devops"
    deployed_by  = "dts-platform-operations"
    managed_by   = "terraform"
  }
}

variable "delete_protection_enabled" {
  description = "Keep a destroyed Key Vault recoverable. Off for environments that are torn down."
  type        = bool
  default     = true
}

variable "postgres_version" {
  description = "Major version of Azure Database for PostgreSQL Flexible Server."
  type        = string
  default     = "16"
}

variable "postgres_admin_username" {
  description = "PostgreSQL administrator login."
  type        = string
  default     = "psqladmin"
}

variable "database_name" {
  description = "Application database created on the server."
  type        = string
  default     = "cms"
}

variable "postgres_sku_name" {
  description = "PostgreSQL compute SKU."
  type        = string
  default     = "GP_Standard_D2s_v3"
}

variable "postgres_storage_mb" {
  description = "PostgreSQL storage in megabytes."
  type        = number
  default     = 65536
}

variable "postgres_backup_retention_days" {
  description = "Days of automated backups retained, between 7 and 35."
  type        = number
  default     = 35
}

variable "postgres_geo_redundant_backup_enabled" {
  description = "Replicate backups to the paired region."
  type        = bool
  default     = true
}

variable "postgres_high_availability_enabled" {
  description = "Zone-redundant high availability. Requires a GP or MO SKU."
  type        = bool
  default     = true
}

variable "key_vault_sku" {
  description = "Key Vault SKU. Expected: standard or premium."
  type        = string
  default     = "standard"
}

variable "registry_sku" {
  description = "Container registry SKU. Expected: Basic, Standard or Premium."
  type        = string
  default     = "Standard"
}

variable "image_name" {
  description = "Repository path of the image inside the registry, without a tag."
  type        = string
  default     = "hmcts/dev-test-backend"
}

variable "image_tag" {
  description = "Immutable image tag to deploy, passed by the pipeline on every run."
  type        = string
}

variable "container_port" {
  description = "Port the application listens on."
  type        = number
  default     = 4000
}

variable "container_cpu" {
  description = "vCPU per replica. Must pair with container_memory."
  type        = number
  default     = 1.0
}

variable "container_memory" {
  description = "Memory per replica. Must pair with container_cpu."
  type        = string
  default     = "2Gi"
}

variable "container_concurrent_requests" {
  description = "Concurrent requests per replica before the scale rule adds another."
  type        = number
  default     = 50
}

variable "min_replicas" {
  description = "Minimum container replicas."
  type        = number
  default     = 2
}

variable "max_replicas" {
  description = "Maximum container replicas."
  type        = number
  default     = 10
}

variable "log_retention_days" {
  description = "Log Analytics retention, between 30 and 730 days."
  type        = number
  default     = 90
}
