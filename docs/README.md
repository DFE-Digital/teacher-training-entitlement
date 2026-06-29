# Documentation

This directory is organised by domain. The orchestrator is in the process of restructuring the legacy flat files (see the GitHub PR list on the `feature/documentation-overhaul` branch). Until step 9, **legacy flat files remain authoritative** for the topics not yet covered by the new structure below.

## New structure

### Registration

- [`overview.md`](registration/overview.md) *(coming soon — step 2a)*
- [`authentication.md`](registration/authentication.md) *(coming soon — step 2b)*
- [`application-submission.md`](registration/application-submission.md) *(coming soon — step 2c)*
- [`change-of-provider.md`](registration/change-of-provider.md) *(coming soon — step 2d)*

### API (Lead Provider)

- [`overview.md`](api/overview.md) *(coming soon — step 3a)*
- [`authentication.md`](api/authentication.md) *(coming soon — step 3b)*
- [`endpoints.md`](api/endpoints.md) *(coming soon — step 3c)*
- [`swagger.md`](api/swagger.md) *(coming soon — step 3d)*

### Admin console

- [`overview.md`](admin/overview.md) *(coming soon — step 4a)*
- [`authentication.md`](admin/authentication.md) *(coming soon — step 4b)*
- [`applications.md`](admin/applications.md) *(coming soon — step 4c)*

### Deployment

- [`overview.md`](deployment/overview.md) *(coming soon — step 5a)*
- [`environments.md`](deployment/environments.md) *(coming soon — step 5b)*
- [`terraform.md`](deployment/terraform.md) *(coming soon — step 5c)*
- [`maintenance-mode.md`](deployment/maintenance-mode.md) *(coming soon — step 5d)*
- [`disaster-recovery.md`](deployment/disaster-recovery.md) *(coming soon — step 5e)*

### Monitoring, logging, alerting

- [`overview.md`](monitoring/overview.md) *(coming soon — step 6a)*
- [`sentry.md`](monitoring/sentry.md) *(coming soon — step 6b)*
- [`logging.md`](monitoring/logging.md) *(coming soon — step 6c)*
- [`uptime-and-ssl.md`](monitoring/uptime-and-ssl.md) *(coming soon — step 6d)*
- [`performance.md`](monitoring/performance.md) *(coming soon — step 6e)*
- [`analytics.md`](monitoring/analytics.md) *(coming soon — step 6f)*

### Development

- [`overview.md`](development/overview.md) *(coming soon — step 7a)*
- [`local-setup.md`](development/local-setup.md) *(coming soon — step 7b)*
- [`azure-access.md`](development/azure-access.md) *(coming soon — step 7c)*
- [`specs-and-linting.md`](development/specs-and-linting.md) *(coming soon — step 7d)*
- [`feature-flags.md`](development/feature-flags.md) *(coming soon — step 7e)*
- [`data-imports.md`](development/data-imports.md) *(coming soon — step 7f)*
- [`ways-of-working.md`](development/ways-of-working.md) *(coming soon — step 7g)*

### Integrations

- [`README.md`](integrations/README.md) *(coming soon — step 8a)*
- [`govuk-one-login.md`](integrations/govuk-one-login.md) *(coming soon — step 8b — TeacherAuth + TRS)*
- [`govuk-notify.md`](integrations/govuk-notify.md) *(coming soon — step 8c)*
- [`gias.md`](integrations/gias.md) *(coming soon — step 8d)*

## Legacy files (will be removed in step 9)

Until each new doc lands, the following files remain the source of truth:

| Legacy file | Will move to |
|---|---|
| `how_does_tte_work.md` | `registration/overview.md` + `registration/application-submission.md` |
| `trn.md` | `integrations/govuk-one-login.md` |
| `swagger.md` | `api/swagger.md` |
| `admins.md` | `admin/authentication.md` |
| `logging.md` | `monitoring/logging.md` |
| `environments.md` | `deployment/environments.md` |
| `disaster_recovery.md` | `deployment/disaster-recovery.md` |
| `maintenance_mode.md` | `deployment/maintenance-mode.md` |
| `setup.md` | `development/local-setup.md` |
| `connecting-to-azure.md` | `development/azure-access.md` |
| `azure-keyvault.md` | `development/azure-access.md` |
| `specs_and_linting.md` | `development/specs-and-linting.md` |
| `feature_flags.md` | `development/feature-flags.md` |
| `importing_data.md` | `development/data-imports.md` |
| `acquiring_new_private_childcare_provider_data.md` | `development/data-imports.md` |
| `eligibility_lists.md` | `development/data-imports.md` |
| `qualifications_api.md` | **DELETED** — service no longer uses the Qualifications API (confirmed via grep, 2026-06-29) |
| `dfe_analytics.md` | `monitoring/analytics.md` |

Files **not** restructured (out of scope for this overhaul):

- `funding.md`
- `sending_emails.md`
- `tte_contracts.md`
- `data_model.md`
- `content_editors/`
- `assets/`

## Content editors

- [`content_editors/api_guidance_pages.md`](content_editors/api_guidance_pages.md) — guidance for content editors maintaining the API guidance pages (separate from the engineering API reference above).