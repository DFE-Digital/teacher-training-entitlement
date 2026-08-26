module "postgres" {
  source = "./vendor/modules/aks//aks/postgres"

  namespace                   = var.namespace
  environment                 = local.environment
  azure_resource_prefix       = var.azure_resource_prefix
  service_name                = var.service_name
  service_short               = var.service_short
  config_short                = var.config_short
  cluster_configuration_map   = module.cluster_data.configuration_map
  use_azure                   = var.deploy_azure_backing_services
  azure_enable_monitoring     = var.enable_monitoring
  azure_enable_backup_storage = var.enable_postgres_backup_storage
  server_version              = var.server_version
  azure_extensions            = ["btree_gin", "citext", "fuzzystrmatch", "pg_trgm"]
  azure_maintenance_window    = var.azure_maintenance_window
  azure_enable_high_availability = var.postgres_enable_high_availability
  azure_sku_name              = var.postgres_flexible_server_sku
}


module "redis-cache" {
  source = "./vendor/modules/aks//aks/redis"

  count                     = var.deploy_cache_redis ? 1 : 0
  namespace                 = var.namespace
  environment               = local.environment
  azure_resource_prefix     = var.azure_resource_prefix
  service_short             = var.service_short
  config_short              = var.config_short
  service_name              = var.service_name
  cluster_configuration_map = module.cluster_data.configuration_map
  use_azure                 = var.deploy_azure_backing_services
  azure_enable_monitoring   = var.enable_monitoring
  azure_patch_schedule      = [{ "day_of_week" : "Sunday", "start_hour_utc" : 01 }]
  server_version            = "6"
}

module "redis-managed-cache" {
  source = "./vendor/modules/aks//aks/redis_managed"

  count                 = var.deploy_managed_redis ? 1 : 0
  name                  = "cache"
  namespace             = var.namespace
  environment           = local.environment
  azure_resource_prefix = var.azure_resource_prefix
  service_name          = var.service_name
  service_short         = var.service_short
  config_short          = var.config_short

  cluster_configuration_map = module.cluster_data.configuration_map

  use_azure               = var.deploy_azure_backing_services
  azure_enable_monitoring = var.enable_monitoring

  azure_managed_redis_sku = var.redis_managed_cache_sku_name
}

moved {
  from = module.redis-managed-cache.azurerm_private_endpoint.main[0]
  to   = module.redis-managed-cache[0].azurerm_private_endpoint.main[0]
}

moved {
  from = module.redis-managed-cache.azurerm_managed_redis.main[0]
  to   = module.redis-managed-cache[0].azurerm_managed_redis.main[0]
}

moved  {
  from = module.redis-cache.azurerm_redis_cache.main[0]
  to   = module.redis-cache[0].azurerm_redis_cache.main[0]
}

moved {
  from = module.redis-cache.azurerm_private_endpoint.main[0]
  to   = module.redis-cache[0].azurerm_private_endpoint.main[0]
}

moved {
  from = module.redis-managed-cache.azurerm_monitor_metric_alert.memory[0]
  to   = module.redis-managed-cache[0].azurerm_monitor_metric_alert.memory[0]
}

moved {
  from = module.redis-cache.azurerm_monitor_metric_alert.memory[0]
  to   = module.redis-cache[0].azurerm_monitor_metric_alert.memory[0]
}
