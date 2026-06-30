# Skylight — Application Performance Monitoring

[Skylight](https://www.skylight.io) is the TTE service's APM tool. It profiles
production and pre-production traffic, segments each request into its component
parts, and surfaces the slow endpoints, N+1 queries, memory hotspots, and
background jobs that affect user-facing latency.

Skylight is the performance lens; it complements but does not replace
[Sentry](./sentry.md) (errors) and [Logging](./logging.md) (Logit/ELK).

---

## What Skylight does

Profiles every request, segmenting time spent in routing, controllers,
ActiveRecord, view rendering, and external HTTP calls. Detects N+1 queries
automatically, tracks background job (Delayed Job) execution and memory
allocation per endpoint, and tags every trace with the deploy `git_sha`
for release-to-release comparison.

---

## Configuration

Wired in three places:

1. **`Gemfile`** — `gem "skylight"` (line 49), in the production group.
2. **`config/skylight.yml`** — 7-line configuration file:

   ```yaml
   ---
   deploy:
     git_sha: <%= ENV["COMMIT_SHA"] %>
   ignored_endpoints:
     - MonitoringController#healthcheck
     - MonitoringController#up
   log_file: tmp/skylight.log
   ```

3. **`config/application.rb`** (line 81) — registers additional environments:

   ```ruby
   config.skylight.environments += ["review", "sandbox", "staging"]
   ```

**Authentication:** `SKYLIGHT_AUTHENTICATION` holds the token from
<https://www.skylight.io>. Stored in Azure Key Vault and injected into the
AKS pod by the deploy pipeline — never checked into the repo.

**Deploy tagging:** `deploy.git_sha` is interpolated from
`ENV["COMMIT_SHA"]`, set by GitHub Actions at deploy time. Every trace can
be filtered to a specific deploy, making regressions easy to bisect.

**Ignored endpoints:** `MonitoringController#healthcheck` and
`MonitoringController#up` are excluded so healthcheck probes don't flood
the dashboard. See [Overview](./overview.md#1-healthcheck-endpoints-in-house).

**Log file:** Skylight writes its own diagnostic log to `tmp/skylight.log`
— agent output only, not application telemetry. For application logs see
[Logging](./logging.md).

---

## Environment matrix

Skylight is **not** loaded in `development` or `test`. It is active in
every deployed environment — production (default) plus `review`, `sandbox`,
and `staging` (registered in `application.rb` line 81). A separate dashboard
per environment lets you confirm a fix in staging before promoting.

---

## Accessing Skylight

- **Dashboard:** <https://www.skylight.io> (DfE Skylight account).
- **Auth token:** in Key Vault, injected as `SKYLIGHT_AUTHENTICATION`.
- **Requesting access:** ask the **Lead Developer** or **Platform team**
  in `#tta-tech`. New users must be added to the Skylight organisation.
- **Environment selector:** at the top of the dashboard — choose
  `production`, `sandbox`, `staging`, or a `review-*` app.

---

## Reading a trace

A Skylight trace is a stacked bar chart. Each segment is time spent in one
layer of the request stack.
Reading the segments, top-down: **Endpoint bar** = total wall-clock time
(sort by this to find the slowest routes). **App** = controller +
before_actions; large means a heavy `before_action`. **ActiveRecord** = DB
time; repeated, near-identical queries are flagged as **N+1** (yellow
badge). **View** = template rendering; large means a slow partial or
missing collection cache. **Memory allocation** = toggle on the trace;
sharp upward trends across deploys suggest a leak.

---

## Common use cases

**Identify an N+1 query** — open the endpoint, look for a yellow **N+1**
badge on the ActiveRecord segment, click through to the offending action,
fix in the model with `includes(:association)` (or `preload` /
`eager_load`), and re-deploy; the badge disappears on the next release.

**Find the slowest endpoints** — open the **Endpoints** tab and sort by
**p95 response time** (default) or **total time**. Click any endpoint to
see its aggregate trace profile and query list.

**Compare across deploys** — open an endpoint trace, click **Compare**,
and select two `git_sha` values. Skylight renders side-by-side segment
timings; red is a regression, green is an improvement.

**Detect a memory leak** — open an endpoint, switch to **Allocations**
view, and sort by **allocation per request** over the last 24h. An
endpoint whose allocation grows steadily across deploys — without a
matching drop after a GC-friendly change — is the leak candidate.

**Profile a background job** — filter the endpoint list to the **Job**
namespace. Skylight shows the same segment breakdown as a request (AR,
app code, mailer calls). Useful for the `:dfe_analytics` and
statement-generation queues.

---

## Relationship with other monitoring

| Tool       | Catches                               | Does **not** catch                            |
|------------|---------------------------------------|-----------------------------------------------|
| Skylight   | Slow endpoints, N+1, memory, job time | Exceptions, error stacks, structured logs     |
| Sentry     | Exceptions, unhandled errors, traces  | Aggregate performance trends, N+1 detection   |
| Logit      | Free-form log search, deploy history  | Trending dashboards, per-request segmentation |
| StatusCake | External uptime, SSL expiry           | Internal slowness, in-app errors              |

A request that is slow but does not raise: Skylight sees it, Sentry does
not. A request that raises a 500: Sentry sees it, Skylight may show a
normal-looking trace (the exception happened *after* the work).

---

## Key files

| File                      | Role                                                       |
|---------------------------|------------------------------------------------------------|
| `Gemfile`                 | `skylight`                                                 |
| `config/skylight.yml`     | Ignored endpoints, deploy `git_sha`, log file              |
| `config/application.rb`   | Adds `review`, `sandbox`, `staging` to active environments |
| `tmp/skylight.log`        | Skylight agent diagnostic log                              |
| Azure Key Vault           | Holds `SKYLIGHT_AUTHENTICATION` token                      |
| GitHub Actions deploy job | Sets `COMMIT_SHA` and `SKYLIGHT_AUTHENTICATION` env vars   |

---

## See also

- [Monitoring overview](./overview.md) — full stack and environment matrix
- [Sentry](./sentry.md) — error tracking & performance traces
- [Logging](./logging.md) — Logit / ELK log shipping
- [Uptime & SSL](./uptime-and-ssl.md) — StatusCake external monitoring
