# 0001. API V2 serializer and opt-in includes

Status: Accepted (interim, api-v2/001)

## Context

API V2 replaces *applications* with *training* and follows JSON:API. V1 uses
Blueprinter with a bespoke error envelope and must not change.

## Decision

- Use `jsonapi-serializer` for V2 only. V1 Blueprinter is untouched.
- V2 routes live in `config/routes/api/v2.rb`, drawn before the shared
  catch-all so V2 paths get V2 errors.
- V2 success and error documents use `application/vnd.api+json` with an
  `errors` array, including 401 (auth middleware) and 404. V1 bodies are unchanged.
- Related resources are opt-in via `include`: `teacher`, `outcome`, `surveys`,
  `expected_declarations`. Unknown, invalid or nested paths return 400.
- Linkage and related links are always present; `included` appears only when
  requested, de-duplicated by type/id, with no nested includes.
- `include=contract` is deferred.

## Include guarantees

- Absent `include`: no `included` member; linkage still returned.
- Included data is limited to the provider's current training; outcomes come
  only from that provider's non-voided completed declarations.
- Relationship data is not paginated or truncated; page size bounds primary data.

## Trade-offs

- Pros: standard documents, smaller default payloads, explicit allow-list
  avoids exposing arbitrary associations.
- Cons: a second serialization stack; clients must request includes; no
  sparse fieldsets or nested includes yet.

## Known issue: contract identity

A contract's JSON:API id is the course cohort UUID, which can be shared by
several training records with different assignment dates. A shared type/id
cannot carry per-training dates in one document, so contract inclusion is
deferred. Clients get linkage plus
`/contracts/:id?training_id=<UUID>` for context. The representation is to be
resolved in api-v2/025.

## Consequences

Interim fields (email, role, experience, uplift, surveys) are placeholders and
may change when api-v2/013, 025 and 026 land. See the
[V2 usage guide](../api/v2-usage.md).
