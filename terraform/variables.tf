# --- Naming and tagging ---

variable "product" {
  description = "Product name; first segment of every resource name."
  type        = string
  default     = "hmcts-dev-test"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,20}$", var.product))
    error_message = "product must be 3-20 characters of lowercase letters, digits or hyphens."
  }
}

variable "component" {
  description = "Component within the product, e.g. backend."
  type        = string
  default     = "backend"

  validation {
    condition     = can(regex("^[a-z0-9-]{2,15}$", var.component))
    error_message = "component must be 2-15 characters of lowercase letters, digits or hyphens."
  }
}

variable "env" {
  description = "Environment short name. Also drives the HA and backup defaults."
  type        = string

  validation {
    condition     = contains(["dev", "test", "stg", "prod"], var.env)
    error_message = "env must be one of: dev, test, stg, prod."
  }
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "uksouth"
}

variable "common_tags" {
  description = "Tags applied to every resource. Cost centre and owner go here."
  type        = map(string)
  default = {
    application = "hmcts-dev-test"
    managedBy   = "Terraform"
    repository  = "hmcts/hmcts-dev-test-backend"
  }
}

variable "builtFrom" {
  description = "Git SHA that produced this deployment; tagged for traceability."
  type        = string
  default     = "unknown"
}

# --- Networking ---

variable "vnet_address_space" {
  description = "Address space for the service VNet."
  type        = list(string)
  default     = ["10.20.0.0/16"]

  validation {
    condition     = length(var.vnet_address_space) > 0
    error_message = "vnet_address_space must contain at least one CIDR block."
  }
}

variable "postgres_subnet_prefix" {
  description = "CIDR for the subnet delegated to PostgreSQL."
  type        = string
  default     = "10.20.1.0/24"
}

variable "container_apps_subnet_prefix" {
  description = "CIDR for the Container Apps subnet. /23 is the minimum for a Consumption-only environment."
  type        = string
  default     = "10.20.4.0/23"
}

# --- PostgreSQL ---

variable "postgres_version" {
  description = "PostgreSQL major version."
  type        = string
  default     = "16"
}

variable "postgres_sku_name" {
  description = "Flexible Server compute SKU."
  type        = string
  default     = "GP_Standard_D2ds_v5"
}

variable "postgres_storage_mb" {
  description = "Provisioned storage in MB. Cannot be reduced later."
  type        = number
  default     = 32768

  validation {
    condition     = var.postgres_storage_mb >= 32768
    error_message = "postgres_storage_mb must be at least 32768 (32 GiB)."
  }
}

variable "postgres_backup_retention_days" {
  description = "Days of automated backups to retain."
  type        = number
  default     = 14

  validation {
    condition     = var.postgres_backup_retention_days >= 7 && var.postgres_backup_retention_days <= 35
    error_message = "postgres_backup_retention_days must be between 7 and 35."
  }
}

variable "postgres_admin_username" {
  description = "Administrator login. The password is generated, not supplied."
  type        = string
  default     = "psqladmin"
}

variable "db_name" {
  description = "Application database name."
  type        = string
  default     = "devtest"
}

# --- Container app ---

variable "container_image" {
  description = "Image reference including an explicit tag or digest."
  type        = string

  validation {
    condition     = can(regex(":|@sha256:", var.container_image))
    error_message = "container_image must include an explicit tag or digest, not a floating 'latest'."
  }
}

variable "container_cpu" {
  description = "vCPU for the app container. Container Apps only allows certain cpu/memory pairs."
  type        = number
  default     = 0.5
}

variable "container_memory" {
  description = "Memory for the app container, e.g. \"1Gi\". Must be 2x the cpu value."
  type        = string
  default     = "1Gi"
}

variable "min_replicas" {
  description = "Minimum replicas. Keep at 1 or above in prod to avoid cold starts."
  type        = number
  default     = 1
}

variable "max_replicas" {
  description = "Maximum replicas the autoscaler can reach."
  type        = number
  default     = 5

  validation {
    condition     = var.max_replicas >= var.min_replicas
    error_message = "max_replicas must be greater than or equal to min_replicas."
  }
}

variable "log_retention_days" {
  description = "Log Analytics retention period."
  type        = number
  default     = 30
}

# --- Registry ---

variable "registry_server" {
  description = "Registry hostname the image is pulled from."
  type        = string
  default     = "ghcr.io"
}

variable "registry_username" {
  description = "Registry username, or null for an anonymously pullable image."
  type        = string
  default     = null
  sensitive   = true
}

variable "registry_password" {
  description = "Registry token, or null for an anonymously pullable image."
  type        = string
  default     = null
  sensitive   = true
}
