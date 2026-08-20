variable "cluster" {
  type        = string
  description = "AKS cluster where this app is deployed. Either 'test' or 'production'"
}
variable "namespace" {
  type        = string
  description = "AKS namespace where this app is deployed"
}
variable "environment" {
  type        = string
  description = "Name of the deployed environment in AKS"
}
variable "azure_resource_prefix" {
  type        = string
  description = "Standard resource prefix. Usually s189t01 (test) or s189p01 (production)"
}
variable "config" {
  type        = string
  description = "Long name of the environment configuration, e.g. development, staging, production..."
}
variable "config_short" {
  type        = string
  description = "Short name of the environment configuration, e.g. dv, st, pd..."
}
variable "service_name" {
  type        = string
  description = "Full name of the service. Lowercase and hyphen separated"
}
variable "service_short" {
  type        = string
  description = "Short name to identify the service. Up to 6 charcters."
}
variable "deploy_azure_backing_services" {
  type        = bool
  default     = true
  description = "Deploy real Azure backing services like databases, as opposed to containers inside of AKS"
}
variable "enable_postgres_ssl" {
  type        = bool
  default     = true
  description = "Enforce SSL connection from the client side"
}
variable "enable_postgres_backup_storage" {
  type        = bool
  default     = false
  description = "Create a storage account to store database dumps"
}
variable "docker_image" {
  type        = string
  description = "Docker image full name to identify it in the registry. Includes docker registry, repository and tag e.g.: ghcr.io/dfe-digital/teacher-pay-calculator:673f6309fd0c907014f44d6732496ecd92a2bcd0"
}
variable "external_url" {
  type        = string
  default     = null
  description = "Healthcheck URL for StatusCake uptime monitoring"
}
variable "apex_url" {
  type        = string
  default     = null
  description = "URL for StatusCake SSL certificate monitoring. Only for DNS zone apex domain."
}
variable "statuscake_contact_groups" {
  type        = list(any)
  default     = []
  description = "ID of the contact group in statuscake web UI"
}
variable "enable_monitoring" {
  type        = bool
  default     = false
  description = "Enable monitoring and alerting"
}
variable "send_traffic_to_maintenance_page" {
  type        = bool
  default     = false
  description = "During a maintenance operation, keep sending traffic to the maintenance page instead of resetting the ingress"
}

locals {
  environment_variables = yamldecode(file("${path.module}/config/${var.config}.yml"))

  #azure_credentials = try(jsondecode(var.azure_credentials_json), null)
  ## not used anywhere?
  #access_domain          = "${var.service_name}-${var.environment}${var.app_suffix}-web.${module.cluster_data.ingress_domain}"
  #access_external_domain = try(local.environment_variables["ACCESS_EXTERNAL_DOMAIN"], local.access_domain)

  postgres_ssl_mode = var.enable_postgres_ssl ? "require" : "disable"

  redis = {
    legacy = {
      cache_url = module.redis-cache.url
    }
    managed = {
      cache_url = module.redis-managed-cache.url
    }
  }
  selected_redis = local.redis[var.redis_mode]
}

variable "enable_logit" { default = true }

variable "app_replicas" {
  type        = number
  description = "Number of replicas of the web app"
  default     = 1
}

variable "app_suffix" {
  type    = string
  default = ""
}

variable "container_delete_retention_days" {
  type        = number
  default     = null
  description = "Number of days to retain deleted containers"
}

variable "blob_delete_retention_days" {
  type        = number
  default     = null
  description = "Number of days to retain deleted blobs"
}

variable "azure_credentials_json" {
  default     = null
  description = "JSON containing the service principal authentication key when running in automation"
}

variable "deploy_redis_cache" {
  type    = bool
  default = true
}

variable "worker_memory_max" {
  type    = string
  default = "1Gi"
}

variable "worker_replicas" {
  type    = number
  default = 1
}

variable "command" {
  type    = list(string)
  default = []
}

variable "enable_dfe_analytics_federated_auth" {
  description = "Create the resources in Google cloud for federated authentication and enable in application"
  type        = bool
  default     = false
}

variable "postgres_flexible_server_sku" {
  default = "B_Standard_B1ms"
}

variable "azure_maintenance_window" {
  default = null
}

variable "postgres_enable_high_availability" {
  default = false
}

variable "gcp_table_deletion_protection" {
  type        = bool
  description = "Prevents deletion of the event table. Default: true"
  default     = true
  nullable    = false
}

variable "redis_managed_cache_sku_name" { default = "Balanced_B1" }

variable "redis_managed_queue_sku_name" { default = "Balanced_B1" }

variable "redis_mode" {
 description = "Whether to use Cache for Redis or Managed Redis"
 type        = string
 default     = "legacy" # or "managed"
 validation {
   condition     = contains(["managed", "legacy"], var.redis_mode)
   error_message = "redis_mode must be either 'legacy' (Cache for Redis) or 'managed' (Managed Redis)."
   }
 }

 variable "server_version" {
   description = "Sets version of Postgres DB to use"
   type        = string
   default     = "17"
 }
