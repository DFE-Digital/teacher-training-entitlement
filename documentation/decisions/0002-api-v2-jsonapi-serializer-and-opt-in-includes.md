# 0002. API V2 serializer and opt-in includes

## Status

Accepted (interim, first API V2 endpoints)

## Context

API V2 follows JSON:API and keeps `application` as the name of its main
resource. V1 uses Blueprinter with a bespoke error envelope and must not change.
Later V2 endpoints (teachers, contracts, outcomes, surveys, declarations,
expected declarations, statements) reuse the same scaffolding.

## Decision

- Use `jsonapi-serializer` for V2 only (`app/serializers/api/v2/`). V1
  Blueprinter serializers are untouched.
- V2 routes live in `config/routes/api/v2.rb`, drawn before the shared API
  catch-all so unknown V2 paths get V2 errors.
- V2 is behind the `Feature::API_V2_ENABLED` ("API V2 enabled") feature flag,
  checked in `API::V2::BaseController`. While it is off, every V2 request
  returns a JSON:API 404 (after authentication) and V1 is unaffected.
- V2 success and error documents use `application/vnd.api+json`. Errors are an
  `errors` array of `{ status, title, detail }`, including errors raised
  outside V2 controllers: 401 from `Middleware::ApiAuthentication`, 429 from
  Rack::Attack, and 404/422/500 from the exceptions app (`ErrorsController`).
  Parameter errors also carry `source.parameter`. `APIV2Path`
  (`lib/api_v2_path.rb`) is the single check for "is this a V2 request". V1
  bodies and status codes are unchanged.
- Shared controller concerns in `app/controllers/concerns/api/v2/`:
  - `Includes` — `allowed_includes` declares each endpoint's allow-list;
    `requested_includes` validates `?include=` (comma-separated, de-duplicated)
    and runs as a `before_action`, so nothing is queried or traversed for a
    rejected request. Nested paths are accepted only if the complete path is
    listed; none are approved yet.
  - `Filters` — `allowed_filters` plus strict parsing: `filter` must be a flat
    hash of supported keys with string values; bad values (including malformed
    TRNs and emails) return 400.
  - `Sorting` — `allowed_sorts` with a default; `sort` uses the V1 `+`/`-`
    syntax, and unknown or repeated fields return 400.
  - `Pagination` — the JSON:API
    [cursor pagination profile](https://jsonapi.org/profiles/ethanresnick/cursor-pagination/)
    (see below).

## Visibility

- As in V1, a provider sees every application it is or was assigned to, once
  each. This uses `ApplicationLeadProvider.preferred_per_application`, which
  picks the current assignment, else the latest previous one. Previously
  assigned applications have status `reassigned` and a `contract_unassigned_at`.
- `outcome` links only the latest outcome of the provider's own completed,
  billable or voidable declarations, otherwise `null`.

## Pagination and sorting

- Cursor (keyset) pagination replaces page numbers: `page[size]` (default 100,
  maximum 3000), `page[after]`, `page[before]`. A size above the maximum is
  rejected, not clamped. Range pagination (`after` and `before` together) and
  unknown `page[...]` keys are rejected with 400.
- `API::V2::CursorPaginator` takes the full sort order, which always ends with
  the application id (`ecf_id`) as a unique tie-breaker. A cursor is the
  Base64-encoded sort order plus that row's key values, so it stays valid while
  rows change and is rejected if replayed with another sort.
- Links are `self`, `prev` and `next`; they keep filters, `include` and `sort`.
  A link is `null` only when the server knows there are no results in that
  direction. An empty page after `page[after]=X` still links `prev` to
  `page[before]=X`, and an empty page before `page[before]=X` links `next` to
  `page[after]=X`, so clients are never stranded.
  Each page costs one query for `size + 1` rows; no totals are computed.
- The default and `sort=updated_at` order use the effective `updated_at`.

## Effective updated_at

Clients sync with `sort=updated_at` and `filter[updated_since]`, so an
application must count as updated when one of its V2 attributes or its
teacher changes, not just its own row. The effective `updated_at` is
`GREATEST(...)` of:

| Source                                  | Why                                                                     |
|-----------------------------------------|-------------------------------------------------------------------------|
| `applications.updated_at`               | the application itself (course cohort, funding, status, institution id) |
| `application_lead_providers.updated_at` | the provider's assignment: `reassigned` status, `contract_*_at`         |
| `institutions.updated_at`               | nested `institution` (touched when the school/provider/authority changes) |
| `users.significantly_updated_at`        | the teacher (TRN, email); same "significant change" rule as V1          |

Not included:

- declarations and outcomes: statement runs (`payable`, `paid`), clawbacks and
  voids would otherwise mark every application on a statement as updated each
  month, and clients would re-sync large parts of their data. As a result, a
  change to the `outcome` linkage alone does not move `updated_at`.
- the course cohort (`contract`): only its id appears in the application, and that
  changes through `applications.course_cohort_id`. Its own attributes belong to
  the contract resource.
- the course and its milestones (`course.identifier`, `expected_declarations`):
  reference data. A change would mark every application on the course as updated,
  and a deleted milestone leaves no timestamp anyway.
- surveys: no survey data exists yet. When surveys land (api-v2/009), their
  `updated_at` must be added to the expression
  (`API::V2::Applications::Query::EFFECTIVE_UPDATED_AT_SQL`).

The value is computed once, in an inner subquery of the listing query that is
aliased as `application_lead_providers`; `ORDER BY`, the `updated_since` filter
and the cursor keyset refer to its `effective_updated_at` column. The number of
queries per page stays the same and nothing needs a schema change or backfill.
V1 data, `applications.updated_at` and analytics are unaffected. The rejected
alternative was `touch:`-style callbacks that bump `applications.updated_at`.
That would change V1 `filter[updated_since]` and analytics data, needs callbacks
on several write paths (including `update_all`), and doesn't cover historical
rows. It also wouldn't make the sort index-backed, because
`applications.updated_at` has no index today.

Trade-off: an expression across joined tables can't use an index, so each page
reads the provider's visible applications through the
`application_lead_providers.lead_provider_id` index, joins them by primary key
and keeps the top `size + 1` rows with a heap sort. A full sync therefore costs
O(N²/size) row reads for a provider with N applications. PostgreSQL flattens
the subquery, so the plan repeats the cheap four-column `GREATEST` in the join
filter and sort key, but there is no correlated subquery. Before the flag is
enabled in production, `EXPLAIN ANALYZE` must be run against a production-sized
snapshot for the largest lead provider at page sizes 100 and 3000. If the numbers
are poor, a denormalised and indexed column could replace the expression. That
would be a schema change with analytics review, and the API contract wouldn't
change.

## Include guarantees

- Absent `include`: no `included` member; relationship linkage and related
  links are always returned.
- Valid `include`: `included` is present (an empty array when nothing is
  linked), de-duplicated by type/id by the serializer, and only contains
  records reachable from provider-visible primary data.
- Unsupported paths return 400 with JSON:API errors and no data.
- Only permitted paths are preloaded, in a fixed number of queries per page.

## To-many bounding policy

Primary data is bounded by page size (max 3000). To-many relationships are not
paginated or truncated, so nothing is cut off. Each must be naturally bounded:

- `expected_declarations`: one per course milestone (a handful per course).
- `surveys`: at most 2 per application, for specific courses only. They are
  always empty until survey data exists.

No to-many cap is needed.

A future to-many relationship that is not naturally bounded must be links-only
(no linkage, not includable), as `statement.expected_declarations` will be.

## Contract identity

A contract's id is the course cohort `ecf_id` (as V1 schedules). Several
applications can share one contract but have different effective dates, so the
included `contract` only carries shared attributes (`academic_year`, `course`,
`term`). Application-specific dates are reached through the related link
`/api/v2/contracts/:id?application_id=<UUID>`, delivered with the contracts
endpoints.

## Trade-offs

- Pros: standard documents, smaller default payloads, an explicit allow-list
  avoids exposing arbitrary associations.
- Cons: a second serialization stack; clients must request includes; no sparse
  fieldsets or nested includes yet.

## Consequences

Interim fields (role, experience, funding uplift, status reason, confirmation
reason, surveys) are placeholders and may change as later V2 work lands. See
the [V2 usage guide](../api/v2-usage.md).
