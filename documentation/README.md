# Documentation

This directory is organised by domain.

## Registration

- [`overview.md`](registration/overview.md) — course cohorts, funding eligibility, registration wizard
- [`authentication.md`](registration/authentication.md) — sign-in flow, user provisioning, session expiry
- [`application-submission.md`](registration/application-submission.md) — submission wizard, validation, workflow
- [`change-of-provider.md`](registration/change-of-provider.md) — provider transfer process

## API (Lead Provider)

- [`overview.md`](api/overview.md) — architecture, authentication modes, versioning
- [`authentication.md`](api/authentication.md) — Bearer token auth, token management
- [`endpoints.md`](api/endpoints.md) — all endpoints, request/response schemas, status transitions
- [`swagger.md`](api/swagger.md) — Swagger/OpenAPI spec, RSwag, schema drift check

## Admin console

- [`overview.md`](admin/overview.md) — role model, feature flag page, cohort/course management
- [`authentication.md`](admin/authentication.md) — OTP-based sign-in wizard, session handling

## Deployment

- [`overview.md`](deployment/overview.md) — architecture, CI/CD pipeline, environments
- [`environments.md`](deployment/environments.md) — environment breakdown, DNS, monitoring
- [`terraform.md`](deployment/terraform.md) — service vs state Terraform, key resources
- [`maintenance-mode.md`](deployment/maintenance-mode.md) — enable/disable, Makefile targets
- [`disaster-recovery.md`](deployment/disaster-recovery.md) — backup strategy, restore procedures

## Monitoring, logging, alerting

- [`overview.md`](monitoring/overview.md) — tools, dashboards, alerting strategy
- [`sentry.md`](monitoring/sentry.md) — error tracking, cron monitoring, performance traces
- [`logging.md`](monitoring/logging.md) — Semantic Logger, structured JSON, log shipping
- [`uptime-and-ssl.md`](monitoring/uptime-and-ssl.md) — Pingdom, Statuscake, certificate renewal
- [`performance.md`](monitoring/performance.md) — Skylight APM, N+1 detection, Knapsack timing
- [`analytics.md`](monitoring/analytics.md) — DfE Analytics, BigQuery event pipeline

## Development

- [`overview.md`](development/overview.md) — tech stack, auth modes, env vars, CI pipeline
- [`local-setup.md`](development/local-setup.md) — Docker Compose, local dev, Codespaces, Tilt
- [`azure-access.md`](development/azure-access.md) — Azure CLI, AKS/kubectl, Konduit DB tunnels
- [`specs-and-linting.md`](development/specs-and-linting.md) — RSpec, RuboCop, SCSS-Lint, test config
- [`feature-flags.md`](development/feature-flags.md) — Flipper, admin UI, Feature service object
- [`data-imports.md`](development/data-imports.md) — GIAS schools, childcare providers, NPQ eligibility lists
- [`ways-of-working.md`](development/ways-of-working.md) — branching, PR workflow, CI, Dependabot

## Integrations

- [`README.md`](integrations/README.md) — integration index
- [`govuk-one-login.md`](integrations/govuk-one-login.md) — TeacherAuth OIDC proxy + TRS API
- [`govuk-notify.md`](integrations/govuk-notify.md) — email notifications via single template
- [`govuk-gias.md`](integrations/govuk-gias.md) — daily school data import from Azure edubase

## Data model

- [`data.md`](data.md) — data dictionary, key relationships, links to auto-generated ERD
- [`domain-model.md`](domain-model.md) — auto-generated Mermaid entity-relationship diagram (run `bundle exec mermaid_erd` to refresh)

## Remaining legacy files (not restructured)

- [`content_editors/`](content_editors/)
- [`assets/`](assets/)
