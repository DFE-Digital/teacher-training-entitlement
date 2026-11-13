# API V2 usage guide (interim)

`GET /api/v2/training` lists the authenticated lead provider's current training
as JSON:API documents. It is the only V2 endpoint implemented; V1 is unchanged.
Teacher, contract, outcome, survey and expected-declaration URLs that appear in
relationship `links` are **not yet live** (planned: api-v2/012, 013, 025, 026).

V2 is interim and not yet published in Swagger (see [Public docs](#public-docs)).

## Request

```
GET /api/v2/training?filter[course]=npd-eirt&include=teacher,outcome
Authorization: Bearer <token>
```

Responses use `Content-Type: application/vnd.api+json`. Auth is the same
Bearer token as V1 ([`authentication.md`](./authentication.md)).

### Filters

Filters combine with AND. List-valued filters take comma-separated values
(any match). Values must be strings; `filter` must be a flat hash.

| Filter                     | Value                                | Matches                             |
|----------------------------|--------------------------------------|-------------------------------------|
| `filter[course]`           | list of course identifiers           | `courses.identifier`                |
| `filter[term]`             | list of `autumn`, `spring`, `summer` | course cohort term                  |
| `filter[academic_year]`    | list of 4-digit years                | course cohort academic year         |
| `filter[funding_eligible]` | `true` / `false`                     | `applications.eligible_for_funding` |
| `filter[funding_uplift]`   | `true` / `false`                     | always no results (uplift is null)  |
| `filter[teacher_trn]`      | list of TRNs                         | `users.trn`                         |
| `filter[teacher_ecf_id]`   | list of UUIDs                        | `users.ecf_id`                      |
| `filter[teacher_email]`    | list of emails                       | `users.email`                       |
| `filter[updated_since]`    | ISO 8601 timestamp                   | `applications.updated_at >=`        |

### Pagination

Pagy countless: `page[page]` (default 1) and `page[per_page]` (default 100,
capped at 3000). Ordered by `applications.id`. No totals are returned.

```json
"links": { "self": "https://host/api/v2/training?...&page[page]=1&page[per_page]=100",
           "prev": null, "next": "https://host/api/v2/training?...&page[page]=2&page[per_page]=100" },
"meta": { "page": 1, "per_page": 100 }
```

Pagination links are absolute and keep every other query parameter (filters,
include). Relationship `links.related` are relative paths.

### Includes

`include` is opt-in, comma-separated, de-duplicated. Allowed: `teacher`,
`outcome`, `surveys`, `expected_declarations`. Nested paths (`teacher.outcomes`)
and `contract` are rejected with 400. Without `include` there is no `included`
member, but relationship linkage and links are still returned.

### Errors

JSON:API `errors` array, same content type, including middleware errors.

| Status | When                                                              |
|--------|-------------------------------------------------------------------|
| `400`  | unknown/invalid include; unknown filter; non-hash, array or nested filter; invalid filter value; invalid page params |
| `401`  | missing or invalid token                                          |
| `404`  | unknown `/api/v2/*` path                                          |

```json
{ "errors": [{ "status": "400", "title": "Bad request", "detail": "The include path(s) contract are not supported" }] }
```

## Response

```json
{
  "data": [{
    "id": "<application ecf_id UUID>", "type": "training",
    "attributes": {
      "email": "teacher@example.com",
      "contract_assigned_at": "...", "contract_unassigned_at": null,
      "created_at": "...", "updated_at": "...",
      "status": "pending", "status_reason": null,
      "course": { "identifier": "npd-eirt", "role": null, "experience": null },
      "funding": { "eligible": true, "uplift": null, "confirmed": null,
                   "choice": "dfe", "reason": null, "confirmation_reason": null },
      "institution": { "institution_type": "school", "reference_number": "...",
                       "ukprn": "...", "country_code": "GBR", "subdivision": "ENG" }
    },
    "relationships": {
      "teacher": { "data": { "id": "0012345", "type": "teacher" }, "links": { "related": "/api/v2/teachers/0012345" } },
      "contract": { "data": { "id": "<course cohort UUID>", "type": "contract" }, "links": { "related": "/api/v2/contracts/<id>?training_id=<training UUID>" } },
      "outcome": { "data": null, "links": { "related": null } },
      "surveys": { "data": [], "links": { "related": "/api/v2/surveys?filter[training_id]=<UUID>" } },
      "expected_declarations": { "data": [{ "id": "<UUID>_started", "type": "expected-declaration" }],
                                 "links": { "related": "/api/v2/expected-declarations?filter[training_id]=<UUID>" } }
    }
  }],
  "links": {}, "meta": {}
}
```

### Field notes

- **Scope**: only the provider's *current* assignments. Former assignments are not listed.
- **`email`**: currently `users.email` (interim; no separate work-email source).
- **`role`, `experience`, `funding.uplift`, `status_reason`, `confirmation_reason`**: always `null` for now.
- **`funding`**: `choice` falls back to `dfe` when unset; `confirmed` is `funded_place` (`true`/`false`/`null`); `eligible` is `eligible_for_funding`; `reason` is `previously-funded`, `establishment-ineligible` or `null`.
- **`institution.institution_type`** (replaces `category`): `school`, `private_childcare_provider`, `local_authority`.
- **Teacher id**: TRN string (leading zeroes kept) when known, else `ecf_id` UUID. Teacher attributes `ecf_id` and `trn` are stable; UUID lookup is planned for the teacher detail ticket (api-v2/012), not live.
- **Outcome**: latest outcome from the requesting provider's completed declarations that are billable or voidable; voided and other providers' history never appear. No outcome: `data: null`. Included outcome attributes: `state`, `completion_date`.
- **Surveys**: always empty (linkage and includes) until api-v2/013 supplies a source.
- **Expected declarations**: one per course-cohort milestone, including types already received, id `<training UUID>_<declaration_type>`. Included resources only carry `declaration_type`; window, status and statement data wait for api-v2/026 and imply nothing about finance.
- **Contract**: linkage and context link only; `include=contract` is deferred (see [ADR 0001](../decisions/0001-api-v2-jsonapi-serializer-and-opt-in-includes.md)).

## Public docs

V2 has no OpenAPI spec: `API::Version` (`lib/api/version.rb`) lists only `v1`
and `/api/docs/v2` does not exist. Next action for developers: add rswag
specs for V2 and register the version per [`swagger.md`](./swagger.md); this
guide is the reference until then.

## Code map

| Concern        | Location                                   |
|----------------|--------------------------------------------|
| Routes         | `config/routes/api/v2.rb`                  |
| Controllers    | `app/controllers/api/v2/`                  |
| Serializers    | `app/serializers/api/v2/`                  |
| Query/outcomes | `app/services/trainings/`                  |
