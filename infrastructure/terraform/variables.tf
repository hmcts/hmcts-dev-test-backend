variable "project_name" {
  type        = string
  description = "Name of the project used in resource naming conventions."
  default     = "hmcts"
}

variable "environment" {
  type        = string
  description = "Deployment environment (e.g., dev, perf, prod)."
  default     = "dev"
}

variable "location" {
  type        = string
  description = "Azure region where resources will be deployed."
  default     = "northeurope"
}

variable "location_short" {
  type        = string
  description = "Short region code (e.g., eus, wue, uks, eun)."
  default     = "eun"
}

variable "db_admin_username" {
  type        = string
  description = "Administrator username for PostgreSQL Flexible Server."
  default     = "psqladmin"
  sensitive   = true
}

variable "container_image" {
  type        = string
  description = "Container image to deploy into Azure Container Apps."
  default     = "mcr.microsoft.com/azuredocs/aci-helloworld:latest"
}
