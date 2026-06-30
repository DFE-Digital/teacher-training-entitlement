# Terraform — Infrastructure as Code

This project uses two separate Terraform root modules under `terraform/`:

| Module          | Path                     | Purpose                                                             |
|-----------------|--------------------------|---------------------------------------------------------------------|
| **Application** | `terraform/application/` | AKS workloads (web, worker), PostgreSQL, Redis, storage, monitoring |
| **Domains**     | `terraform/domains/`     | DNS zone, Front Door, SSL, CNAME records per environment            |

Both modules share the same Terraform version (`= 1.14.5`) and state backend pattern (Azure
Storage), but are planned and applied independently.

## Workspace layout

```
terraform/
├── application/                 # App infrastructure root module
│   ├── terraform.tf             # Providers & backend config
│   ├── application.tf           # Web + worker deployments
│   ├── database.tf              # PostgreSQL flexible server + Redis cache
│   ├── storage.tf               # Azure Storage account for file uploads
│   ├── secrets.tf               # Infrastructure Key Vault (StatusCake token)
│   ├── cluster_data.tf          # AKS cluster metadata lookup
│   ├── statuscake.tf            # Uptime + SSL monitoring
│   ├── dfe_analytics.tf         # BigQuery federated auth (Google provider)
│   ├── variables.tf             # All input variables
│   ├── output.tf                # Deployment URL outputs
│   └── config/                  # Per-environment YAML + tfvars.json
├── domains/
│   ├── infrastructure/          # DNS zone creation (applied rarely)
│   └── environment_domains/     # Per-environment Front Door + CNAME records
│       └── config/              # Domain tfvars per env
```

## State management

All state lives in Azure Storage blobs. The backend is configured in `terraform.tf`:

```hcl
backend "azurerm" {
  container_name = "terraform-state"
}
```

The storage account and resource group name are computed per environment by the
Makefile's `composed-variables` target:

| Env        | Storage account       | Resource group         | State key               |
|------------|-----------------------|------------------------|-------------------------|
| Staging    | `s189t01cpdttesttfsa` | `s189t01-cpdtte-st-rg` | `staging.tfstate`       |
| Sandbox    | `s189p01cpdttesbtfsa` | `s189p01-cpdtte-sb-rg` | `sandbox.tfstate`       |
| Production | `s189p01cpdttepdtfsa` | `s189p01-cpdtte-pd-rg` | `production.tfstate`    |
| Review     | `s189t01cpdttervtfsa` | `s189t01-cpdtte-rv-rg` | `terraform-<N>.tfstate` |

State keys are set at `terraform init` time via `-backend-config=key=<env>.tfstate`.

## Providers

| Provider     | Version    | Purpose                                               |
|--------------|------------|-------------------------------------------------------|
| `azurerm`    | `4.61.0`   | Azure resources (PostgreSQL, Redis, storage, AKS)     |
| `kubernetes` | `2.32.0`   | Deployments, configmaps, secrets in AKS               |
| `helm`       | (implicit) | Chart deployments (handled by the AKS module)         |
| `statuscake` | `2.2.2`    | Uptime + SSL monitoring alerts                        |
| `google`     | (latest)   | BigQuery resources for DfE Analytics (federated auth) |

The Kubernetes provider authenticates via `kubelogin` using the cluster credentials
looked up by `module.cluster_data`:

```hcl
provider "kubernetes" {
  host                   = module.cluster_data.kubernetes_host
  cluster_ca_certificate = module.cluster_data.kubernetes_cluster_ca_certificate
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "kubelogin"
    args        = module.cluster_data.kubelogin_args
  }
}
```

The StatusCake provider reads its API token from the infrastructure Key Vault
(`module.infrastructure_secrets.map.STATUSCAKE-API-TOKEN`).

## Application module (`application.tf`)

The file defines three top-level modules:

### 1. Application configuration (`module.application_configuration`)

Injects environment variables and secrets into Kubernetes ConfigMap and Secret
resources. Sources:

- **Config YAML** — `config/${var.config}.yml` is decoded with `yamldecode` and
  merged into the ConfigMap. Each environment has its own `.yml` file for
  non-sensitive settings (One Login URL, Teacher Auth domain, client ID).
- **Static vars** — `ENVIRONMENT_NAME`, `PGSSLMODE`, `RAILS_ENV`, upload storage
  account, BigQuery project/dataset.
- **Secret vars** — `DATABASE_URL` (from `module.postgres.url`), `REDIS_CACHE_URL`,
  `AZURE_STORAGE_ACCESS_KEY`, `GOOGLE_CLOUD_CREDENTIALS` — written to the Kubernetes
  Secret.
- **Review app override** — When `environment == "review"`, `HOSTING_DOMAIN` is
  computed from the cluster ingress domain.

### 2. Web deployment (`module.web_application`)

Deploys the Rails server as an AKS deployment:

| Property                   | Value                                                                              |
|----------------------------|------------------------------------------------------------------------------------|
| Docker image               | `var.docker_image` (full `ghcr.io/dfe-digital/teacher-training-entitlement:<sha>`) |
| Replicas                   | `var.app_replicas` (default `1`)                                                   |
| Port                       | `8080`                                                                             |
| Liveness / readiness probe | HTTP GET `/up`                                                                     |
| Command                    | `var.command` (empty by default → Dockerfile CMD)                                  |
| Logit                      | Always enabled                                                                     |
| Maintenance page           | `var.send_traffic_to_maintenance_page`                                             |
|                            |                                                                                    |

The Dockerfile CMD runs `db:migrate` before starting Puma, so the web pod handles
schema migrations at boot.

### 3. Worker deployment (`module.worker_application`)

Same Docker image, different command — runs the Delayed::Job background worker:

| Property       | Value                                                          |
|----------------|----------------------------------------------------------------|
| Command        | `["/bin/sh", "-c", "bundle exec rake jobs:work"]`              |
| Liveness probe | `["pgrep", "-f", "rake"]`                                      |
| Replicas       | `var.worker_replicas` (default `1`)                            |
| Max memory     | `var.worker_memory_max` (default `"1Gi"`)                      |
| Logit          | `var.enable_logit`                                             |
| Destroy delay  | 15 seconds via `time_sleep.wait_15_seconds` (review apps only) |

The 15-second destroy delay prevents Delayed::Job from erroring out when Postgres
is removed before in-flight jobs finish.

### 4. Backing services (`database.tf`)

- **PostgreSQL flexible server** — `module.postgres` (version 16). SKU, HA, backup
  storage, extensions (`btree_gin`, `citext`, `fuzzystrmatch`, `pg_trgm`) are
  controlled by variables.
- **Redis cache** — `module.redis-cache` (version 6). Patching scheduled for Sundays
  at 01:00 UTC.

Both support `use_azure` toggle — review apps set `deploy_azure_backing_services: false`,
running containers inside AKS instead.

### 5. Monitoring (`statuscake.tf`)

Conditional on `var.enable_monitoring`:

- **Uptime alert** — polls `var.external_url` (the `/healthcheck.json` endpoint).
- **SSL alert** — monitors `var.apex_url` for certificate expiry.
- **Contact groups** — who gets notified (e.g. production: `[282453, 356280]`).

## Variables

### Core environment identifiers

| Variable                | Example                   | Description                              |
|-------------------------|---------------------------|------------------------------------------|
| `cluster`               | `"test"` / `"production"` | AKS cluster name lookup                  |
| `namespace`             | `"cpd-production"`        | Kubernetes namespace                     |
| `environment`           | `"production"`            | Environment name (also sets `RAILS_ENV`) |
| `azure_resource_prefix` | `"s189p01"`               | Azure resource naming prefix             |
| `config_short`          | `"pd"`                    | Short config code for naming             |
| `service_short`         | `"cpdtte"`                | Short service identifier                 |

### Application

| Variable                           | Default    | Production | Description                              |
|------------------------------------|------------|------------|------------------------------------------|
| `app_replicas`                     | `1`        | `2`        | Web pod count                            |
| `worker_replicas`                  | `1`        | `2`        | Worker pod count                         |
| `worker_memory_max`                | `"1Gi"`    | —          | Worker memory limit                      |
| `docker_image`                     | (required) | —          | Full image ref from ghcr.io              |
| `command`                          | `[]`       | —          | Override Dockerfile CMD (used by review) |
| `send_traffic_to_maintenance_page` | `false`    | —          | Ingress maintenance mode toggle          |

### Postgres

| Variable                            | Default           | Production            |
|-------------------------------------|-------------------|-----------------------|
| `postgres_flexible_server_sku`      | `B_Standard_B1ms` | `GP_Standard_D4ds_v5` |
| `postgres_enable_high_availability` | `false`           | `true`                |
| `enable_postgres_ssl`               | `true`            | `true`                |
| `enable_postgres_backup_storage`    | `false`           | `true`                |
| `azure_maintenance_window`          | `null`            | Sunday 03:00          |

### Redis

| Variable             | Default | Description                                 |
|----------------------|---------|---------------------------------------------|
| `deploy_redis_cache` | `true`  | Deploy Redis (off for review if not needed) |

### Monitoring & logging

| Variable                          | Default | Production                     | Description                          |
|-----------------------------------|---------|--------------------------------|--------------------------------------|
| `enable_monitoring`               | `false` | `true`                         | StatusCake alerts + Azure monitoring |
| `enable_logit`                    | `true`  | `true`                         | Log shipping to Logit (Logstash)     |
| `external_url`                    | `null`  | `https://.../healthcheck.json` | StatusCake uptime target             |
| `apex_url`                        | `null`  | Apex domain URL                | StatusCake SSL target                |
| `statuscake_contact_groups`       | `[]`    | `[282453, 356280]`             | Alert notification groups            |
| `blob_delete_retention_days`      | `null`  | `7`                            | Soft-delete retention for blobs      |
| `container_delete_retention_days` | `null`  | `7`                            | Soft-delete retention for containers |

### DfE Analytics

| Variable                              | Default | Enabled in          | Description                             |
|---------------------------------------|---------|---------------------|-----------------------------------------|
| `enable_dfe_analytics_federated_auth` | `false` | Production, sandbox | BigQuery federated auth via GCP WIF     |
| `gcp_table_deletion_protection`       | `true`  | —                   | Prevents accidental BigQuery table drop |
    
## Per-environment configuration

Each environment has two config files in `terraform/application/config/`:

### `.tfvars.json` — Terraform variables

Highlights of what differs:

```json
// production.tfvars.json — Full production spec
{
  "postgres_flexible_server_sku": "GP_Standard_D4ds_v5",
  "postgres_enable_high_availability": true,
  "app_replicas": 2,
  "worker_replicas": 2,
  "enable_monitoring": true,
  "enable_logit": true,
  "enable_postgres_backup_storage": true,
  "external_url": "https://teacher-training-entitlement.education.gov.uk/healthcheck.json",
  "statuscake_contact_groups": [282453, 356280],
  "enable_dfe_analytics_federated_auth": true
}
```

```json
// staging.tfvars.json — Minimal; uses defaults for most values
{
  "cluster": "test",
  "environment": "staging",
  "namespace": "cpd-development"
}
```

```json
// sandbox.tfvars.json — Production Azure space, lighter SKU
{
  "cluster": "production",
  "environment": "sandbox",
  "namespace": "cpd-production",
  "enable_logit": true,
  "enable_dfe_analytics_federated_auth": true
}
```

```json
// review.tfvars.json — Ephemeral, container-backed services
{
  "deploy_azure_backing_services": false,
  "enable_postgres_ssl": false,
  "command": ["/bin/sh", "-c", "RAILS_ENV=review bundle exec rails db:environment:set db:schema:load db:migrate && bundle exec rails server -b 0.0.0.0"],
  "gcp_table_deletion_protection": false
}
```

### `.yml` — App config (non-secret env vars)

```yaml
# production.yml
ONE_LOGIN_HOME_URL: https://home.account.gov.uk
TEACHER_AUTH_DOMAIN: https://preprod.authorise-access-to-a-teaching-record.education.gov.uk/
TEACHER_AUTH_CLIENT_ID: teacher-training-entitlement
```

Staging, sandbox, and review use `home.integration.account.gov.uk` for One Login.

## Domains module

### Infrastructure (`terraform/domains/infrastructure/`)

Creates the DNS zone and default NS records. Applied rarely — only when the zone
is first provisioned.

- State key: `domains_infrastructure.tfstate`
- Run: `make domains-infra-init && make domains-infra-plan && make domains-infra-apply`
- Variables: `hosted_zone` (zone name), `deploy_default_records` (NS, SOA).

### Environment domains (`terraform/domains/environment_domains/`)

Per-environment Front Door configuration, CNAME records, and caching.

Per-environment domain configs:

```json
// production.tfvars.json within environment_domains/
{
  "hosted_zone": {
    "teacher-training-entitlement.education.gov.uk": {
      "front_door_name": "s189p01-cpdtte-dom-fd",
      "resource_group_name": "s189p01-cpdtte-dom-rg",
      "domains": ["apex"],
      "cached_paths": ["/assets/*", "/packs/*"],
      "environment_short": "pd",
      "origin_hostname": "teacher-training-entitlement-production.teacherservices.cloud"
    }
  },
  "rate_limit_max": 1000,
  "allow_aks": true,
  "block_ip": true
}
```

| Env        | Domain record | Origin hostname                       | Rate limit |
|------------|---------------|---------------------------------------|------------|
| Production | `apex` (root) | `*.teacherservices.cloud`             | 1000 req/s |
| Staging    | `staging`     | `*staging.test.teacherservices.cloud` | 300 req/s  |
| Sandbox    | `sandbox`     | `*sandbox.teacherservices.cloud`      | 300 req/s  |

Run per environment: `make staging domains-plan`, `make staging domains-apply`.

## CI integration

The `.github/actions/deploy-environment-to-aks/` composite action runs Terraform
via the Makefile:

```yaml
- name: Apply Terraform
  run: |
    make ci ${{ inputs.environment }} terraform-apply
    cd terraform/application && echo "url=$(terraform output -raw url)" >> $GITHUB_OUTPUT
  env:
    TF_VAR_statuscake_api_token: ${{ inputs.statuscake-api-token }}
    DOCKER_IMAGE_TAG: ${{ inputs.deploy-commit-sha }}
    PULL_REQUEST_NUMBER: ${{ inputs.pull-request-number }}
```

The `make ci` target sets `AUTO_APPROVE=-auto-approve` and `SKIP_CONFIRM=true` so
deployments run non-interactively. The environment target (`production`, `staging`,
etc.) includes the matching `global_config/*.sh` script, which sets `TF_VAR_*`
variables automatically.

For review apps, the action also seeds the database after apply:

```yaml
kubectl exec -n cpd-development deployment/teacher-training-entitlement-review-${{ env.PR_NUMBER }} \
  -- sh -c "cd /app && RAILS_ENV=review bundle exec rails db:seed:replant"
```

## Makefile targets

All commands run from the repository root and chain environment selection:

| Target               | What it does                                               | Example                                       |
|----------------------|------------------------------------------------------------|-----------------------------------------------|
| `terraform-init`     | Clones the AKS module, configures backend, sets `TF_VAR_*` | `make staging terraform-init`                 |
| `terraform-plan`     | `init` + `terraform plan -var-file config/...`             | `make staging terraform-plan`                 |
| `terraform-apply`    | `init` + `terraform apply -auto-approve` (CI)              | `make staging terraform-apply`                |
| `terraform-destroy`  | `init` + `terraform destroy`                               | `make review terraform-destroy PR_NUMBER=123` |
| `domains-plan`       | Plan DNS environment changes                               | `make production domains-plan`                |
| `domains-apply`      | Apply DNS environment changes                              | `make production domains-apply`               |
| `domains-infra-plan` | Plan DNS zone infrastructure                               | `make domains-infra-plan`                     |

The `composed-variables` target computes derived names (`RESOURCE_GROUP_NAME`,
`STORAGE_ACCOUNT_NAME`, `KEYVAULT_NAMES`) from the `global_config/` env script
values, so you never need to type long Azure resource names.

## Common workflows

### Change web replicas

```bash
# 1. Edit the tfvars file
#    terraform/application/config/staging.tfvars.json
#    Add: "app_replicas": 3

# 2. Plan and apply
make staging terraform-plan   # review the diff
make staging terraform-apply   # applies immediately
```

### Roll back a Docker image

```bash
make production terraform-plan \
  DOCKER_IMAGE_TAG=<previous-sha> \
  CONFIRM_PRODUCTION=yes

make production terraform-apply \
  DOCKER_IMAGE_TAG=<previous-sha> \
  CONFIRM_PRODUCTION=yes
```

The `DOCKER_IMAGE_TAG` env var sets `TF_VAR_docker_image` to
`ghcr.io/dfe-digital/teacher-training-entitlement:<tag>`.

### Add a new environment variable

1. **Non-sensitive** — Add the key-value to the environment's `.yml` file (e.g.
   `config/production.yml`). It will appear in the Kubernetes ConfigMap on next
   apply.
2. **Sensitive** — Store the value in the app Key Vault (`*-app-kv`) and reference
   it in `application_configuration.secret_variables` in `application.tf`.
3. **Apply** — `make <env> terraform-apply`.

### Enable/disable monitoring

Set `"enable_monitoring": true` (or `false`) in the `.tfvars.json` and apply.
This toggles StatusCake uptime/SSL alerts and Azure monitor diagnostics.

### Put up the maintenance page

Set `"send_traffic_to_maintenance_page": true` in `.tfvars.json` and apply. Or
use the Makefile workflow:

```bash
make production enable-maintenance GITHUB_TOKEN=xxx
make production disable-maintenance
```

## Related docs

- [Deployment overview](overview.md) — pipeline, container runtime, scaling, AKS access
- [Environments](environments.md) — permanent envs, state storage, Key Vaults
- [Maintenance mode](maintenance-mode.md) — fail-over to static page
- [Disaster recovery](disaster-recovery.md) — backup and restore
- [Azure access](../development/azure-access.md) — Azure CLI, PIM, and Konduit DB tunnels
