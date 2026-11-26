# API V2 usage guide (interim)

`GET /api/v2/applications` and `GET /api/v2/applications/:id` return the
applications the authenticated lead provider is or was assigned to as JSON:API
documents. They are the only V2 endpoints implemented; V1 is unchanged. Teacher, contract,
outcome, survey and expected-declaration URLs that appear in relationship
`links` are **not yet live**.

V2 is interim and not yet published in Swagger (see [Public docs](#public-docs)).
It is behind the **"API V2 enabled"** feature flag (Admin > Settings > Features).
While the flag is off every `/api/v2/*` request returns a JSON:API `404`
(after authentication), and V1 is unaffected either way.
Design decisions are recorded in
[ADR 0002](../decisions/0002-api-v2-jsonapi-serializer-and-opt-in-includes.md).

## Requests

```
GET /api/v2/applications?filter[course]=npd-eirt&include=teacher,outcome
GET /api/v2/applications/<application UUID>?include=contract
Authorization: Bearer <token>
```

Responses use `Content-Type: application/vnd.api+json`. Auth is the same
Bearer token as V1 ([`authentication.md`](./authentication.md)).

### Filters (list only)

Filters combine with AND. List-valued filters take comma-separated values
(any match); an empty value (e.g. `filter[course]=a,,b`, or a leading or
trailing comma) returns a `400`. Values must be strings; `filter` must be a
flat hash.

`filter`, `sort` and `page` are list-only: sending any of them (with any key or
value) to show returns a `400` naming the parameter in `source.parameter`,
before any data is loaded. They are rejected rather than ignored.

| Filter                     | Value                                | Matches                                  |
|----------------------------|--------------------------------------|------------------------------------------|
| `filter[course]`           | list of course identifiers           | course identifier                        |
| `filter[term]`             | list of `autumn`, `spring`, `summer` | contract term                            |
| `filter[academic_year]`    | list of 4-digit years                | contract academic year                   |
| `filter[funding_eligible]` | `true` / `false`                     | `funding.eligible`                       |
| `filter[funding_uplift]`   | `true` / `false`                     | always no results (uplift is null)       |
| `filter[teacher_trn]`      | list of 7-digit TRNs                 | teacher TRN                              |
| `filter[teacher_ecf_id]`   | list of UUIDs                        | teacher `ecf_id`                         |
| `filter[email]`            | list of valid emails (exact match)   | application `email`                      |
| `filter[updated_since]`    | ISO 8601 timestamp, e.g. `2025-01-01T00:00:00Z` | effective `updated_at >=` (see below) |

### Sorting (list only)

`sort` uses the V1 syntax: a comma-separated list of distinct fields, each
optionally prefixed with `+` (ascending, the default) or `-` (descending).
Sortable fields: `created_at`, `updated_at` (the effective `updated_at`, see
[Field notes](#field-notes)). The default is `sort=updated_at`. The application
id is always added as a final ascending tie-breaker, so the order is unique.
Any other field, a repeated field or an empty entry returns a `400` whose
`links.type` is the profile's `unsupported-sort` error. Encode `+` as `%2B`; an
unencoded `+` arrives as a space and is treated as ascending.

To sync changes, page through `sort=updated_at` and resume later with
`filter[updated_since]` set to the last `updated_at` you processed.

### Pagination (list only)

The list follows the JSON:API
[cursor pagination profile](https://jsonapi.org/profiles/ethanresnick/cursor-pagination/):

| Parameter      | Meaning                                                            |
|----------------|--------------------------------------------------------------------|
| `page[size]`   | positive integer, default `100`, maximum `3000`                    |
| `page[after]`  | cursor; returns the results immediately after it                   |
| `page[before]` | cursor; returns the results immediately before it                  |

```json
"links": {
  "self": "https://host/api/v2/applications?filter[course]=npd-eirt&page[size]=100",
  "prev": null,
  "next": "https://host/api/v2/applications?filter[course]=npd-eirt&page[after]=<cursor>&page[size]=100"
}
```

- Links are absolute and keep every other query parameter (filters, `include`,
  `sort`). Follow `next` until it is `null`. `prev` is `null` on the first page.
  A link is `null` only when there are no results in that direction. After a
  `page[after]` request `prev` is always given, and after a `page[before]`
  request `next` is always given. If such a page is empty, the link is built from
  the cursor you sent: an empty `page[after]=X` page has
  `prev` = `page[before]=X`, and an empty `page[before]=X` page has
  `next` = `page[after]=X`.
- Cursors are opaque. They encode the sort order and the position of one row, so
  rows that are added, changed or removed elsewhere don't shift the following
  pages. A row whose `updated_at` changes during a `sort=updated_at` sync moves
  to the end and is returned again there.
- No totals and no `meta` are returned.
- Rejected with `400` and `source.parameter`: a `page[size]` that is not a
  positive integer; a `page[size]` above 3000 (not clamped; the error has
  `meta.page.maxSize` and the profile's `max-size-exceeded` type link); an
  invalid cursor, or one from a different sort order; `page[after]` with
  `page[before]` (range pagination is not supported); any other `page[...]`
  key, including the V1 `page[page]` / `page[per_page]`.

Relationship `links.related` are relative paths.

### Includes

`include` is opt-in, comma-separated and de-duplicated. Allowed: `teacher`,
`contract`, `outcome`, `surveys`, `expected_declarations`. Nested paths
(e.g. `teacher.outcomes`), empty paths (e.g. `include=teacher,`), a repeated
`include[]` parameter and anything else are rejected with 400 before any data
is loaded. Without `include` there is no `included` member, but
relationship linkage and links are still returned. With a valid `include`,
`included` is always present (an empty array if nothing is linked) and each
resource appears once.

### Errors

JSON:API `errors` array with the same content type, including errors from the
authentication middleware, rate limiting and unhandled server errors. Errors
about a query parameter name it in `source.parameter` (e.g. `filter[email]`,
`include`, `sort`, `page[size]`).

| Status | When                                                                                  |
|--------|---------------------------------------------------------------------------------------|
| `400`  | unsupported or empty include path; unknown filter; non-hash, array or nested filter; invalid or empty filter value (including malformed TRN or email); invalid sort; invalid page parameters or cursor; `filter`, `sort` or `page` on show |
| `401`  | missing or invalid token                                                              |
| `404`  | unknown application UUID, application never assigned to you, unknown `/api/v2/*` path, any V2 path while the feature flag is off |
| `422`  | unprocessable content                                                                 |
| `429`  | rate limit exceeded                                                                   |
| `500`  | internal server error                                                                 |

```json
{ "errors": [{ "status": "400", "title": "Bad request",
               "detail": "The include path(s) teacher.outcomes are not supported",
               "source": { "parameter": "include" } }] }
```

## Response

The list returns `data` as an array; show returns a single resource with the
same representation.

```json
{
  "data": [{
    "id": "<application UUID>", "type": "application",
    "attributes": {
      "email": "teacher@example.com",
      "contract_assigned_at": "...", "contract_unassigned_at": null,
      "created_at": "...", "updated_at": "...",
      "status": "pending", "status_reason": null,
      "course": { "identifier": "npd-eirt", "role": null, "experience": null },
      "institution": { "category": "school", "reference_number": "...",
                       "ukprn": "...", "country_code": "GBR", "subdivision": "ENG" },
      "funding": { "eligible": true, "uplift": null, "confirmed": null,
                   "choice": "dfe", "reason": null, "confirmation_reason": null }
    },
    "relationships": {
      "teacher": { "data": { "id": "0012345", "type": "teacher" }, "links": { "related": "/api/v2/teachers/0012345" } },
      "contract": { "data": { "id": "<contract UUID>", "type": "contract" }, "links": { "related": "/api/v2/contracts/<contract UUID>?application_id=<application UUID>" } },
      "outcome": { "data": null, "links": { "related": null } },
      "surveys": { "data": [], "links": { "related": "/api/v2/surveys?filter[application_id]=<application UUID>" } },
      "expected_declarations": { "data": [{ "id": "<application UUID>_started", "type": "expected-declaration" }],
                                 "links": { "related": "/api/v2/expected-declarations?filter[application_id]=<application UUID>" } }
    }
  }],
  "links": { "self": "...", "prev": null, "next": "..." }
}
```

### Field notes

- **Scope**: every application the provider is or was assigned to, once each
  (as V1). If the provider is currently assigned, its current assignment is
  used; otherwise its latest previous one, and `status` is `reassigned`.
- **`email`**: the application's work/notification email
  (`Application#email`, currently the user's email). `filter[email]` matches
  the same value.
- **`contract_assigned_at` / `contract_unassigned_at`**: the requesting
  provider's assignment timestamps; `contract_unassigned_at` is set for
  `reassigned` applications and `null` otherwise.
- **`updated_at`**: the *effective* update time, the latest change to the
  application's V2 attributes or its teacher:
  - the application's own `updated_at`;
  - the requesting provider's assignment (reassignment, `contract_assigned_at`,
    `contract_unassigned_at`);
  - the institution (school, childcare provider or local authority details);
  - the teacher's last significant change (as V1, e.g. a TRN or email change,
    not sign-in token refreshes).

  Declarations and outcomes are not included: statement runs, clawbacks, voids
  and recorded outcomes do not move `updated_at`. Surveys will be added once
  survey data exists. `filter[updated_since]` and `sort=updated_at` use the same
  value.
- **`role`, `experience`, `funding.uplift`, `status_reason`,
  `funding.confirmation_reason`**: always `null` for now.
- **`funding`**: `eligible` is the stored funding eligibility; `reason` is the
  ineligibility reason (e.g. `previously_funded`, `ineligible_setting`) or
  `null`; `confirmed` is the funded place (`true`/`false`/`null`); `choice`
  falls back to `dfe` when unset.
- **`institution.category`**: `school`, `private_childcare_provider`,
  `local_authority`, or `null` without an institution.
- **Teacher id**: TRN string (leading zeroes kept) when known, else the
  `ecf_id` UUID. Included teachers expose `ecf_id` and `trn`.
- **Contract**: id is the course cohort UUID (as V1 `schedule_id`). Included
  contracts expose `academic_year`, `course` and `term`, which are shared by
  every application on it; application-specific dates come from the contextual
  related link.
- **Outcome**: latest outcome from the requesting provider's completed
  declarations that are billable or voidable; voided and other providers'
  history never appear. No outcome: `data: null` and a `null` related link.
  Included outcomes expose `state` and `completion_date`.
- **Surveys**: always empty (linkage and includes) until survey data exists.
- **Expected declarations**: one per course milestone, in milestone order, id
  `<application UUID>_<declaration_type>`. Included resources only carry
  `declaration_type`.

## Public docs

V2 has no OpenAPI spec: `API::Version` (`lib/api/version.rb`) lists only `v1`
and `/api/docs/v2` does not exist. Next action for developers: add rswag specs
for V2 and register the version per [`swagger.md`](./swagger.md); this guide is
the reference until then.

## Code map

| Concern             | Location                                    |
|---------------------|---------------------------------------------|
| Routes              | `config/routes/api/v2.rb`                   |
| Controllers         | `app/controllers/api/v2/`                   |
| Shared concerns     | `app/controllers/concerns/api/v2/`          |
| Serializers         | `app/serializers/api/v2/`                   |
| Queries             | `app/services/api/v2/applications/`         |
| Cursor pagination   | `app/services/api/v2/cursor_paginator.rb`   |
| Feature flag        | `Feature::API_V2_ENABLED` (`app/services/feature.rb`) |
