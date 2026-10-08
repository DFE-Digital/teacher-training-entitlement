provider "google" {
  project = "ecf-bq"
}

module "dfe_analytics" {
  count  = var.enable_dfe_analytics_federated_auth ? 1 : 0
  source = "./vendor/modules/aks//aks/dfe_analytics"

  azure_resource_prefix         = var.azure_resource_prefix
  cluster                       = var.cluster
  namespace                     = var.namespace
  service_short                 = var.service_short
  environment                   = local.environment
  gcp_table_deletion_protection = var.gcp_table_deletion_protection
  gcp_taxonomy_id               = local.gcp_taxonomy_id
  gcp_policy_tag_id             = local.gcp_policy_tag_id
  gcp_keyring                   = local.gcp_keyring
  gcp_key                       = local.gcp_key

}
