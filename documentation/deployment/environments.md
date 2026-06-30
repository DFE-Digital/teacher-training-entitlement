## Overview

| Env        | URL                                                                  | Azure subscription                       | AKS cluster                  | PIM | BA  | Data  | Trigger               |
|------------|----------------------------------------------------------------------|------------------------------------------|------------------------------|-----|-----|-------|-----------------------|
| Production | `teacher-training-entitlement.education.gov.uk`                      | `s189-teacher-services-cloud-production` | `s189p01-tsc-production-aks` | Yes | No  | Real  | Merge to `main` (3rd) |
| Sandbox    | `sandbox.teacher-training-entitlement.education.gov.uk`              | `s189-teacher-services-cloud-production` | `s189p01-tsc-production-aks` | Yes | No  | Dummy | Merge to `main` (2nd) |
| Staging    | `staging.teacher-training-entitlement.education.gov.uk`              | `s189-teacher-services-cloud-test`       | `s189t01-tsc-test-aks`       | No  | Yes | Dummy | Merge to `main` (1st) |
| Review     | `teacher-training-entitlement-review-<N>.test.teacherservices.cloud` | `s189-teacher-services-cloud-test`       | `s189t01-tsc-test-aks`       | No  | No  | Seed  | PR labelled `deploy`  |

## Permanent environments

### Staging

Team-internal, production-like environment on the **test** Azure space. No real data.

- **Healthcheck:** `https://staging.teacher-training-entitlement.education.gov.uk/healthcheck.json`
- **Namespace:** `cpd-development` | **Config short:** `st` | **Modules tag:** `testing`
- **Key Vaults:** `s189t01-cpdtte-st-app-kv`, `s189t01-cpdtte-st-inf-kv`
- **Basic auth:** Required. Credentials in `HTTP-BASIC-AUTH-USER-PASS` secret (`user:pass`):
  ```bash
  az keyvault secret show --vault-name s189t01-cpdtte-st-app-kv \
    --name HTTP-BASIC-AUTH-USER-PASS --query value -o tsv
  ```
- **Auth endpoints:** One Login / Teacher Auth at integration (`home.integration.account.gov.uk`).

### Sandbox

External-facing for lead providers. Runs in the **production** Azure space alongside the live service.

- **Healthcheck:** `https://sandbox.teacher-training-entitlement.education.gov.uk/healthcheck.json`
- **Namespace:** `cpd-production` | **Config short:** `sb` | **Modules tag:** `stable`
- **Key Vaults:** `s189p01-cpdtte-sb-app-kv`, `s189p01-cpdtte-sb-inf-kv`
- **Auth endpoints:** Integration One Login. Dummy data only.

### Production

Live service serving real teacher training entitlement applications.

- **Healthcheck:** `https://teacher-training-entitlement.education.gov.uk/healthcheck.json` (StatusCake monitored, contact groups `282453`, `356280`)
- **Namespace:** `cpd-production` | **Config short:** `pd` | **Modules tag:** `stable`
- **Key Vaults:** `s189p01-cpdtte-pd-app-kv`, `s189p01-cpdtte-pd-inf-kv`
- **Postgres:** `GP_Standard_D4ds_v5` with HA. Web/worker at 2 replicas. Monitoring, Logit, DfE Analytics enabled.
- **Auth endpoints:** Production One Login (`home.account.gov.uk`); preprod Teacher Auth.
- **Safety gate:** `CONFIRM_PRODUCTION=yes` required on all `make production` commands.

## Review apps

Ephemeral environments per PR: `https://teacher-training-entitlement-review-<N>.test.teacherservices.cloud`.

| Property            | Value                                                          |
|---------------------|----------------------------------------------------------------|
| Docker tag          | `pr-<N>`                                                       |
| Terraform state key | `terraform-<N>.tfstate`                                        |
| Resource group      | `s189t01-cpdtte-rv-rg`                                         |
| Storage account     | `s189t01cpdttervtfsa`                                          |
| Backing services    | Container-based (not Azure-managed Postgres/Redis)             |
| DB seed             | `db:seed:replant` after deploy via `deploy-environment-to-aks` |

**Lifecycle:** Created on PR + label `deploy` → seeded → destroyed on merge/close (or via `gh workflow run destroy_review_app.yml -f pr_number=<N>`). Data is ephemeral — not backed up.

## Azure subscriptions

| Subscription                             | Hosts                        | PIM |
|------------------------------------------|------------------------------|-----|
| `s189-teacher-services-cloud-test`       | Staging, review              | No  |
| `s189-teacher-services-cloud-production` | Sandbox, production, domains | Yes |

The test subscription holds development resources only (no real data). The production
subscription requires PIM for all access.

## PIM (Privileged Identity Management)

PIM via Microsoft Entra controls access to the production subscription.

**Elevate:** Visit [PIM Activation](https://portal.azure.com/#view/Microsoft_Azure_PIMCommon/ActivationMenuBlade/~/aadgroup),
activate **Member** role for `s189 CPD production PIM` group, provide justification
(time-bound, typically 8 hours).

**Gating in Makefile:**

```makefile
sandbox: production-cluster          # needs PIM to authenticate to production sub
production: production-cluster       # needs PIM + CONFIRM_PRODUCTION=yes
  $(if $(or ${SKIP_CONFIRM}, ${CONFIRM_PRODUCTION}), , $(error Missing CONFIRM_PRODUCTION=yes))

staging: test-cluster                # no PIM
review: test-cluster
```

## DNS / domains

| Env        | Domain                                                               | Zone                         |
|------------|----------------------------------------------------------------------|------------------------------|
| Production | `teacher-training-entitlement.education.gov.uk`                      | `education.gov.uk`           |
| Sandbox    | `sandbox.teacher-training-entitlement.education.gov.uk`              | `education.gov.uk`           |
| Staging    | `staging.teacher-training-entitlement.education.gov.uk`              | `education.gov.uk`           |
| Review     | `teacher-training-entitlement-review-<N>.test.teacherservices.cloud` | `test.teacherservices.cloud` |

Permanent DNS via `terraform/domains/`. CI deploys domains infrastructure after
production, then per-environment records for staging, sandbox, and production.

## Terraform state

Container `terraform-state` across environment-specific storage accounts.

| Env        | Storage account         | Resource group          | State key                   |
|------------|-------------------------|-------------------------|-----------------------------|
| Staging    | `s189t01cpdttesttfsa`   | `s189t01-cpdtte-st-rg`  | `staging.tfstate`           |
| Sandbox    | `s189p01cpdttesbtfsa`   | `s189p01-cpdtte-sb-rg`  | `sandbox.tfstate`           |
| Production | `s189p01cpdttepdtfsa`   | `s189p01-cpdtte-pd-rg`  | `production.tfstate`        |
| Review     | `s189t01cpdttervtfsa`   | `s189t01-cpdtte-rv-rg`  | `terraform-<N>.tfstate`     |

Naming: `{AZURE_RESOURCE_PREFIX}{SERVICE_SHORT}{CONFIG_SHORT}tfsa` for storage,
`{AZURE_RESOURCE_PREFIX}-{SERVICE_SHORT}-{CONFIG_SHORT}-rg` for resource group.

## AKS clusters

| Cluster                      | Resource group      | Environments        |
|------------------------------|---------------------|---------------------|
| `s189t01-tsc-test-aks`       | `s189t01-tsc-ts-rg` | Staging, review     |
| `s189p01-tsc-production-aks` | `s189p01-tsc-pd-rg` | Sandbox, production |

```bash
make staging get-cluster-credentials    # test cluster
make production get-cluster-credentials # production cluster (PIM needed)
```

## Configuration per environment

**Key Vaults:** Two per environment — application (`*-app-kv`: API keys, Sentry DSN,
feature flags) and infrastructure (`*-inf-kv`: StatusCake token, etc.).

**Terraform vars:** `terraform/application/config/*.tfvars.json` (Postgres SKU,
replicas, monitoring, StatusCake).

**App config:** `*.yml` files in the same directory:

| Env        | One Login URL                             | Teacher Auth domain                                                                        |
|------------|-------------------------------------------|--------------------------------------------------------------------------------------------|
| Production | `https://home.account.gov.uk`             | `preprod.authorise-access-to-a-teaching-record.education.gov.uk/` (shared across all envs) |
| Others     | `https://home.integration.account.gov.uk` | Same as above                                                                              |

**Sentry:** Enabled for all environments. Each has its own `SENTRY_DSN` in the
app Key Vault, read at runtime from `ENV["SENTRY_DSN"]`.

## CI pipeline mapping

From `.github/workflows/deploy.yml`:

```
Push to main: Build → Staging → Sandbox → Production → Domains infra → Domains env (stg/sb/pd)
PR "deploy":   Build → Review app → DB seed
```

Environments deploy sequentially — a failure stops the chain. Manual deploys
(`manual_deploy.yml`) target any environment with a specified Docker tag for rollbacks.

## Data isolation

- **Test subscription** (staging, review): synthetic/seed data only. No real TRNs,
  personal data, or GOV.UK One Login accounts. Dummy admin credentials.
- **Production subscription** (production, sandbox): full DfE data-handling policies.
  Production has real user data; sandbox uses dummy data under the same access controls.

## Smoke test

Each `/healthcheck` endpoint returns JSON. `bin/smoke` validates six checks:

```bash
make staging smoke-test
# or: bin/smoke https://staging.teacher-training-entitlement.education.gov.uk <sha>
```

Checks: commit SHA match, latest migration applied, Redis connected, database
connected, database populated, HTTP 200 on `/`. The action exists but is not wired
into CI.

## Common make targets

Use `make <env> <target>`:

| Target                    | Description                       | Example                                                   |
|---------------------------|-----------------------------------|-----------------------------------------------------------|
| `get-cluster-credentials` | Auth kubectl to cluster           | `make staging get-cluster-credentials`                    |
| `aks-console`             | Rails console (sandboxed)         | `make staging aks-console`                                |
| `aks-ssh`                 | Shell on worker pod               | `make staging aks-ssh`                                    |
| `aks-web-ssh`             | Shell on web pod                  | `make staging aks-web-ssh`                                |
| `konduit`                 | Tunnel Postgres to local db       | `make staging konduit`                                    |
| `konduit-snapshot`        | Tunnel snapshot Postgres          | `make staging konduit-snapshot`                           |
| `scale-app`               | Scale web (`REPLICAS=N`)          | `make production scale-app REPLICAS=3`                    |
| `scale-worker`            | Scale worker (`REPLICAS=N`)       | `CONFIRM_PRODUCTION=yes make production scale-worker R=3` |
| `terraform-plan`          | Preview infra changes             | `make staging terraform-plan`                             |
| `terraform-apply`         | Apply infra changes               | `make staging terraform-apply`                            |
| `smoke-test`              | Run smoke tests against env       | `make staging smoke-test`                                 |
| `db-seed`                 | Seed DB (review, needs PR_NUMBER) | `make ci review db-seed PR_NUMBER=123`                    |

## Related docs

- [Deployment overview](overview.md) — pipeline, container runtime, scaling.
- [Azure access](../development/azure-access.md) — Azure CLI, PIM, and Konduit DB tunnels.
- [Local setup](../development/local-setup.md) — local development environment.
- [Makefile](../../Makefile) — all available targets.
