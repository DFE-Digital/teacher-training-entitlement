# Webhooks endpoints

The service exposes a small read-only surface under `/webhooks/*` for the
**Teacher Record Service (TRS)** — separate from the Lead Provider API under
`/api/v1/*`, with its own token scope and its own OpenAPI document.

Today it holds a single endpoint:

| Method | Path                                 | Controller#action                  | Purpose                                              |
|--------|--------------------------------------|------------------------------------|------------------------------------------------------|
| GET    | `/webhooks/trs/qualifications/{trn}` | `webhooks/trs/qualifications#show` | List a participant's passed qualifications by TRN.   |

Routes live in `config/routes/webhooks.rb`, drawn from `config/routes.rb`
(`draw("/webhooks")`).

## `GET /webhooks/trs/qualifications/{trn}`

Returns the qualifications/certificates a teacher has **passed**, newest first. The
controller looks the participant up by TRN, takes their `ParticipantOutcome`
rows in the `passed` state ordered by `completion_date` descending, and
renders them through `Webhooks::QualificationsSerializer` under a `"data"`
root:

```json
{
  "data": {
    "trn": "0000001",
    "qualifications": [
      { "award_date": "2026-10-05", "course_type": "NPDEIRT" }
    ]
  }
}
```

- `award_date` — the outcome's `completion_date`, formatted `YYYY-MM-DD`.
- `course_type` — the course's short code (`Course#short_code`, reached via
  the outcome's declaration).
- A known TRN with no passed outcomes returns `200` with an empty
  `qualifications` list.

## Authentication

Every webhook endpoint inherits `WebhooksController#authenticate`. Callers
authenticate with an `APIToken` scoped **`teacher_record_service`** — Lead
Provider tokens (`scope: lead_provider`) are rejected. The
`Middleware::ApiAuthentication` layer used by the Lead Provider API does not
apply here: it only matches paths under `^/api/v\d+`, so webhook
authentication happens in the controller itself.

| Status | When                                                                                                                                         |
|--------|----------------------------------------------------------------------------------------------------------------------------------------------|
| `200`  | Valid token, TRN known. The token's `last_used_at` is updated on **every** request — there is no equivalent of the LP middleware's 15-minute cache. |
| `401`  | Missing `Authorization` header. `authenticate_or_request_with_http_token` replies with a `WWW-Authenticate: Token …` challenge; the action never runs. |
| `403`  | Invalid or unknown bearer token. Raised as `WebhooksController::ForbiddenError`, rendered by `forbidden_response` in the `{ "errors": […] }` envelope. |
| `404`  | Valid token, unknown TRN. `User.find_by!` raises `ActiveRecord::RecordNotFound`, rendered as `{ "error": "Resource not found" }`.            |

`APIToken.find_by_unhashed_token` deliberately keeps its `find_by!` semantics;
the webhook controller rescues `ActiveRecord::RecordNotFound` itself so the
other callers (`Middleware::ApiAuthentication`,
`StreamAPIRequestsToBigQueryJob`) keep their existing behaviour.

A known token for local development is seeded as `trs-token`
(`db/seeds/base/add_api_tokens.rb`).

## OpenAPI document and Swagger UI

- Browsable docs at **`/webhooks/docs`** (`Webhooks::DocumentationController`,
  a public page) rendered by the shared `swagger-ui-dist` bundle; the YAML is
  served straight from `public/webhooks/docs/swagger.yaml`.
- The spec is generated from `spec/requests/webhooks/trs/qualifications_spec.rb`
  by a dedicated rake task, `rswag:specs:swaggerize_webhooks`, kept separate
  from the Lead Provider document. Generation mechanics, the `RSWAG_WEBHOOKS`
  switch and the CI drift check are documented in
  [`api/swagger.md`](./api/swagger.md#webhooks-openapi-document).

## Observability

`WebhooksController#set_sentry_context` tags every request `webhook=true` and
emits a `Sentry::Metrics.count("webhook.request")` counter with `path` and
`method` attributes — the webhook analogue of the API's `api.request` metric.

## Code map

| Concern                   | Location                                                    |
|---------------------------|-------------------------------------------------------------|
| Base controller + auth    | `app/controllers/webhooks_controller.rb`                    |
| Qualifications endpoint   | `app/controllers/webhooks/trs/qualifications_controller.rb` |
| Serializer                | `app/serializers/webhooks/qualifications_serializer.rb`     |
| Routes                    | `config/routes/webhooks.rb` (drawn from `config/routes.rb`) |
| Token model / scopes      | `app/models/api_token.rb`                                   |
| Docs UI controller        | `app/controllers/webhooks/documentation_controller.rb`      |
| Generated OpenAPI YAML    | `public/webhooks/docs/swagger.yaml`                         |
| rswag doc spec            | `spec/requests/webhooks/trs/qualifications_spec.rb`         |
| Request (behaviour) spec  | `spec/requests/webhooks/trs_spec.rb`                        |
| Webhooks rake task        | `lib/tasks/rswag_webhooks.rake`                             |
| Seed token                | `db/seeds/base/add_api_tokens.rb`                           |

## Related documentation

- [`api/overview.md`](./api/overview.md) — the Lead Provider API surface
- [`api/authentication.md`](./api/authentication.md) — LP bearer token flow
- [`api/swagger.md`](./api/swagger.md) — OpenAPI generation pipeline
