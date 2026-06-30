# Maintenance mode

The service has **two independent maintenance mechanisms** — a soft informational banner
and a hard ingress-level fail-over.

| Mechanism      | Effect                                               | When to use                           |
|----------------|------------------------------------------------------|---------------------------------------|
| Soft banner    | Yellow GOV.UK notification at page top. Does **not** | Ongoing infra issues — inform without |
|                | block access. Dismissible by user.                   | stopping the service                  |
| Hard fail-over | All traffic routes to a static "service unavailable" | Planned downtime, database restores,  |
|                | page. Rails app inaccessible via primary URL.        | critical incidents                    |

---

## 1. Soft banner (Flipper feature flag)

A GOV.UK yellow notification banner appears at the top of every page when the feature
flag `Maintenance banner` is enabled. Users can dismiss it for 24 hours (cookie-based).

**Toggle via Rails console:**

```ruby
Flipper.enable("Maintenance banner")   # show banner
Flipper.disable("Maintenance banner")  # hide banner
```

**Toggle via admin UI:** Visit `/admin/features` as a SuperAdmin user.

**How dismissal works:**

1. User clicks "Dismiss" → `MaintenanceBannersController#dismiss` sets a cookie
   `dismiss_maintenance_banner_until` to 24 hours from now.
2. `BannerHelper#maintenance_banner_dismissed?` checks the cookie on every page load.
3. The partial `_maintenance_banner.html.erb` skips rendering if the cookie is present
   and valid.

**Key files:**

| File                                                    | Purpose                      |
|---------------------------------------------------------|------------------------------|
| `app/services/feature.rb`                               | Flag constant + check method |
| `app/components/banners/maintenance_component.rb`       | Rendering logic              |
| `app/views/layouts/shared/_maintenance_banner.html.erb` | Partial                      |
| `app/controllers/maintenance_banners_controller.rb`     | Dismissal handler            |
| `app/helpers/banner_helper.rb`                          | Cookie check helper          |
| `config/routes.rb`                                      | Route: `GET .../dismiss`     |

> See [Feature flags](../feature_flags.md) for how Flipper flags are managed.

---

## 2. Hard maintenance (Kubernetes ingress-level fail-over)

Routes all traffic through the Kubernetes ingress to a static nginx container,
bypassing the Rails application entirely. The Rails pods keep running but are
unreachable through the service URL.

### What users see

A GOV.UK-branded "service unavailable" page at `maintenance_page/html/index.html`:

- DfE header with service name "Teacher Training Entitlement"
- Contact email: `continuing-professional-development@digital.education.gov.uk`
- **HTTP 500** for all paths — the browser URL stays unchanged
- Assets (CSS, favicons) served normally from `/stylesheets/` and `/assets/`

Nginx runs on port 8080. Configuration: `maintenance_page/nginx.conf`.

### Docker image

`ghcr.io/dfe-digital/teacher-training-entitlement-maintenance`, built from
`maintenance_page/Dockerfile` (`nginxinc/nginx-unprivileged:1.27.5-alpine3.21`).

```bash
make production maintenance-image-push GITHUB_TOKEN=xxx [MAINTENANCE_IMAGE_TAG=y]
```

If no tag is provided, the current Unix timestamp is used.

### Enable

```bash
make staging enable-maintenance GITHUB_TOKEN=xxx
```

This runs `maintenance-image-push` (build & push image) then
`maintenance_page/scripts/failover.sh`, which:

1. Reads the namespace from `terraform/application/config/${CONFIG}.tfvars.json`.
2. Substitutes `#MAINTENANCE_IMAGE_TAG#` in the deployment template and applies it
   (2 replicas, nginx on port 8080).
3. Creates a ClusterIP service (port 80 → 8080).
4. Creates a maintenance ingress for direct verification (e.g.
   `teacher-training-entitlement-maintenance-staging.test.teacherservices.cloud`).
5. **Re-points the internal ingress** from the Rails app service to the maintenance
   service — this is what redirects all production traffic.
6. Creates a **temp ingress** pointing at the real Rails app for canary testing.

### Disable

```bash
make staging disable-maintenance
```

Runs `maintenance_page/scripts/failback.sh`, which restores the internal ingress to the
main app service and deletes the temp ingress, maintenance ingress, service, and
deployment.

### Canary testing during maintenance

The real app stays reachable at a temporary URL during maintenance:

```
https://teacher-training-entitlement-temp.test.teacherservices.cloud
```

Defined in `maintenance_page/manifests/${CONFIG}/ingress_temp_to_main.yml`. Removed
when maintenance is disabled.

### Production safety gate

```bash
CONFIRM_PRODUCTION=yes make production enable-maintenance GITHUB_TOKEN=xxx
CONFIRM_PRODUCTION=yes make production disable-maintenance
```

Enforced by the Makefile to prevent accidental fail-over on the live service.

### What happens to the app

The Rails pods continue running — the web server still serves on its internal ClusterIP.
Only the primary ingress changes. Developers use the temp URL to verify the app.
Workers process background jobs; migrations can still run.

### Prerequisites

- **AKS credentials** — `make staging get-cluster-credentials` (test cluster) or
  `make production get-cluster-credentials` (requires PIM).
- **GitHub token** with `write:packages` scope for pushing the Docker image.
- **nginx ingress controller** installed on the cluster (managed by
  teacher-services-cloud).

### Key files

| File                                                                       | Purpose                   |
|----------------------------------------------------------------------------|---------------------------|
| `maintenance_page/Dockerfile`                                              | Container build           |
| `maintenance_page/nginx.conf`                                              | Nginx config              |
| `maintenance_page/html/index.html`                                         | Static "unavailable" page |
| `maintenance_page/scripts/failover.sh`                                     | Enable maintenance        |
| `maintenance_page/scripts/failback.sh`                                     | Disable maintenance       |
| `maintenance_page/manifests/maintenance/deployment_maintenance.yml.tmpl`   | Deployment template       |
| `maintenance_page/manifests/maintenance/service_maintenance.yml`           | ClusterIP service         |
| `maintenance_page/manifests/${CONFIG}/ingress_internal_to_main.yml`        | Normal ingress            |
| `maintenance_page/manifests/${CONFIG}/ingress_internal_to_maintenance.yml` | Fail-over ingress         |
| `maintenance_page/manifests/${CONFIG}/ingress_maintenance.yml`             | Direct-access ingress     |
| `maintenance_page/manifests/${CONFIG}/ingress_temp_to_main.yml`            | Canary temp ingress       |

---

## 3. Terraform toggle (secondary safety net)

A boolean variable `send_traffic_to_maintenance_page`
(`terraform/application/variables.tf`, default: `false`). When `true`, the AKS module
changes the Ingress backend to the maintenance service — same effect as the kubectl
workflow.

Not currently set in any `.tfvars.json`. Exists as a Terraform-level safety net when
kubectl access is unavailable.

```bash
TF_VAR_send_traffic_to_maintenance_page=true make staging terraform-apply
```

---

## 4. GitHub Action alternative

`.github/workflows/maintenance.yml` provides a UI-driven interface using
[`DFE-Digital/github-actions/maintenance@master`](https://github.com/DFE-Digital/github-actions).

**Trigger:** GitHub → Actions → "Set maintenance mode" → "Run workflow".

| Input         | Values                  | Description                   |
|---------------|-------------------------|-------------------------------|
| `environment` | `staging`, `production` | Target environment            |
| `mode`        | `enable`, `disable`     | Enable or disable maintenance |

The action internally invokes `failover.sh` / `failback.sh`. This is the same workflow
referenced in the [disaster recovery procedure](disaster-recovery.md).

---

## Decision guide

| Situation                                          | Use                                           |
|----------------------------------------------------|-----------------------------------------------|
| Upstream provider has intermittent issues          | Enable soft banner                            |
| Planned downtime                                   | Enable hard maintenance                       |
| Database restore in progress                       | Enable hard maintenance (see                  |
|                                                    | [disaster recovery](disaster-recovery.md)) |
| Checking the app is healthy behind the static page | Temp URL (auto-created)                       |
| kubectl access unavailable                         | Terraform toggle                              |
| Prefer GitHub UI over command line                 | GitHub Action workflow                        |

## Related docs

- [Deployment overview](overview.md) — pipeline, scaling, AKS access
- [Environments](environments.md) — environment details, PIM, namespaces
- [Feature flags](../feature_flags.md) — Flipper-managed flags
- [Disaster recovery](disaster-recovery.md) — database restore procedure
