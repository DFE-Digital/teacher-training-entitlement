# API V2 usage guide (interim)

`GET /api/v2/applications` and `GET /api/v2/applications/:id` return the
authenticated lead provider's current applications as JSON:API documents. They
are the only V2 endpoints implemented; V1 is unchanged. Teacher, contract,
outcome, survey and expected-declaration URLs that appear in relationship
`links` are **not yet live**.

V2 is interim and not yet published in Swagger (see [Public docs](#public-docs)).
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
(any match). Values must be strings; `filter` must be a flat hash.

| Filter                     | Value                                | Matches                                  |
|----------------------------|--------------------------------------|------------------------------------------|
| `filter[course]`           | list of course identifiers           | course identifier                        |
| `filter[term]`             | list of `autumn`, `spring`, `summer` | contract term                            |
| `filter[academic_year]`    | list of 4-digit years                | contract academic year                   |
| `filter[funding_eligible]` | `true` / `false`                     | `funding.eligible`                       |
| `filter[funding_uplift]`   | `true` / `false`                     | always no results (uplift is null)       |
| `filter[teacher_trn]`      | list of TRNs                         | teacher TRN                              |
| `filter[teacher_ecf_id]`   | list of UUIDs                        | teacher `ecf_id`                         |
| `filter[email]`            | list of emails (exact match)         | application `email`                      |
| `filter[updated_since]`    | ISO 8601 timestamp                   | application `updated_at >=`              |

### Pagination (list only)

Pagy countless: `page[page]` (default 1) and `page[per_page]` (default 100,
capped at 3000). Ordered by internal application id. No totals are returned.

```json
"links": { "self": "https://host/api/v2/applications?...&page[page]=1&page[per_page]=100",
           "prev": null, "next": "https://host/api/v2/applications?...&page[page]=2&page[per_page]=100" },
"meta": { "page": 1, "per_page": 100 }
```

Pagination links are absolute and keep every other query parameter (filters,
include). Relationship `links.related` are relative paths.

### Includes

`include` is opt-in, comma-separated and de-duplicated. Allowed: `teacher`,
`contract`, `outcome`, `surveys`, `expected_declarations`. Nested paths
(e.g. `teacher.outcomes`) and anything else are rejected with 400 before any
data is loaded. Without `include` there is no `included` member, but
relationship linkage and links are still returned. With a valid `include`,
`included` is always present (an empty array if nothing is linked) and each
resource appears once.

### Errors

JSON:API `errors` array with the same content type, including errors from the
authentication middleware and rate limiting.

| Status | When                                                                                  |
|--------|---------------------------------------------------------------------------------------|
| `400`  | unsupported include; unknown filter; non-hash, array or nested filter; invalid filter value; invalid page params |
| `401`  | missing or invalid token                                                              |
| `404`  | unknown application UUID, application not currently assigned to you, unknown `/api/v2/*` path |
| `429`  | rate limit exceeded                                                                   |

```json
{ "errors": [{ "status": "400", "title": "Bad request", "detail": "The include path(s) teacher.outcomes are not supported" }] }
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
  "links": {}, "meta": {}
}
```

### Field notes

- **Scope**: only the provider's *current* assignments. Applications a provider
  was previously assigned are neither listed nor shown (unlike V1, which
  returns them with status `reassigned`).
- **`email`**: the application's work/notification email
  (`Application#email`, currently the user's email). `filter[email]` matches
  the same value.
- **`contract_assigned_at` / `contract_unassigned_at`**: the requesting
  provider's assignment timestamps.
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
- **Expected declarations**: one per course milestone, id
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
