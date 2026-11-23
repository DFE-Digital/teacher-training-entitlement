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
- V2 success and error documents use `application/vnd.api+json`. Errors are an
  `errors` array of `{ status, title, detail }`, including errors raised by
  middleware: 401 from `Middleware::ApiAuthentication` and 429 from
  Rack::Attack. V1 bodies and status codes are unchanged.
- Shared controller concerns in `app/controllers/concerns/api/v2/`:
  - `Includes` — `allowed_includes` declares each endpoint's allow-list;
    `requested_includes` validates `?include=` (comma-separated, de-duplicated)
    and runs as a `before_action`, so nothing is queried or traversed for a
    rejected request. Nested paths are accepted only if the complete path is
    listed; none are approved yet.
  - `Filters` — `allowed_filters` plus strict parsing: `filter` must be a flat
    hash of supported keys with string values; bad values return 400.
  - `Pagination` — Pagy countless pagination with `links` (`self`, `prev`,
    `next`) and `meta` (`page`, `per_page`). No totals are computed. Links keep
    every other query parameter, including filters and `include`.

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
paginated or truncated; each must be naturally bounded:

- `expected_declarations`: one per course milestone (a handful per course).
- `surveys`: always empty until survey data exists.

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
