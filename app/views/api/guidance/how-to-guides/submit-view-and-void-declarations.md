# Submit, view and void declarations

Providers must submit declarations in line with contractual schedules and milestone dates.

These declarations will trigger payment from DfE to providers.

When providers submit declarations, API response bodies will include data about which financial statement the given declaration applies to. Providers can then view financial statement payment dates to check when the invoicing period, and expected payment date, will be for the given declaration.

## Test that you can submit declarations ahead of time

`X-With-Server-Date` is a custom JSON header supported in the test environment. It lets providers test their integrations and ensure they're able to submit declarations for future milestone dates.

The `X-With-Server-Date` header lets providers simulate future dates, and therefore allows providers to test declaration submissions for future milestone dates.

<div class="govuk-inset-text">
  It's only valid in the test environment. Attempts to submit future declarations in the production environment (or without this header in the test environment) will be rejected as part of milestone validation.
</div>

To test declaration submission functionality, include:

* the header `X-With-Server-Date` as part of declaration submission request
* the value of your chosen date in the ISO 8601 format with time and time zone (the RFC 3339 format). For example:

```
X-With-Server-Date: 2022-01-10T10:42:00Z
```

## Submit a started declaration

```
POST /api/v1/applications/{id}/declarations/started
```

Notify DfE a participant has started a course by submitting a `started` declaration against their application, in line with milestone 1 dates.

The `participant_id` and `course_identifier` are derived from the application, so they do not need to be included in the request body.

Request bodies must include the `declaration_date` and `delivery_partner_id` attributes.

Successful requests will return a response body with declaration data.

Any attempts to submit duplicate declarations will return an error message.

<div class="govuk-inset-text">
  Providers should store the returned declaration ID for management tasks.
</div>

### Example request body

```json
{
  "data": {
    "type": "declaration",
    "attributes": {
      "declaration_date": "2025-09-15T10:00:00Z",
      "delivery_partner_id": "524df095-f9bf-4f9d-ba4c-772545a99e60"
    }
  }
}
```

### Example response body

```json
{
  "data": {
    "id": "d0b4a32e-a272-489e-b30a-cb17131457fc",
    "type": "declaration",
    "attributes": {
      "application_id": "ab3a7848-1208-7679-942a-b4a70eed400a",
      "declaration_type": "started",
      "course_identifier": "tte-early-years",
      "declaration_date": "2025-09-15T10:00:00Z",
      "state": "submitted",
      "has_passed": null,
      "statement_id": null,
      "clawback_statement_id": null,
      "lead_provider_name": "Example Institute",
      "ineligible_for_funding_reason": null,
      "delivery_partner_id": "524df095-f9bf-4f9d-ba4c-772545a99e60",
      "delivery_partner_name": "Regional Delivery Partner",
      "created_at": "2025-09-15T10:00:00.000Z",
      "updated_at": "2025-09-15T10:00:00.000Z"
    }
  }
}
```

## Submit a completed declaration

```
POST /api/v1/applications/{id}/declarations/completed
```

Notify DfE a participant has completed a course by submitting a `completed` declaration against their application, in line with completion milestone dates.

A completed declaration may automatically create a participant outcome.

Request bodies must include the `declaration_date` and `has_passed` attributes.

### Example request body

```json
{
  "data": {
    "type": "declaration",
    "attributes": {
      "declaration_date": "2026-06-30T10:00:00Z",
      "has_passed": true
    }
  }
}
```

## Retrieve multiple declarations

```
GET /api/v1/declarations
```

Use this endpoint to:

* view all declarations which have been submitted to date
* check declaration submissions
* identify if any are missing
* void declarations which have been submitted in error

Providers can filter results by adding filters to the parameter. For example: `GET /api/v1/declarations?filter[application_id]=ab3a7848-1208-7679-942a-b4a70eed400a` or `GET /api/v1/declarations?filter[cohort]=2025&filter[updated_since]=2025-11-13T11:21:55Z`

Providers can also filter by `declaration_type`. For example: `GET /api/v1/declarations?filter[application_id]=db3a7848-7308-4879-942a-c4a70ced400a&filter[declaration_type]=started`

### Example response body

```json
{
  "data": [
    {
      "id": "d0b4a32e-a272-489e-b30a-cb17131457fc",
      "type": "declaration",
      "attributes": {
        "application_id": "ab3a7848-1208-7679-942a-b4a70eed400a",
        "declaration_type": "started",
        "course_identifier": "tte-early-years",
        "declaration_date": "2025-09-15T10:00:00Z",
        "state": "submitted",
        "has_passed": null,
        "statement_id": null,
        "clawback_statement_id": null,
        "lead_provider_name": "Example Institute",
        "ineligible_for_funding_reason": null,
        "delivery_partner_id": "524df095-f9bf-4f9d-ba4c-772545a99e60",
        "delivery_partner_name": "Regional Delivery Partner",
        "created_at": "2025-09-15T10:00:00.000Z",
        "updated_at": "2025-09-15T10:00:00.000Z"
      }
    }
  ]
}
```

## Retrieve a single declaration

```
GET /api/v1/declarations/{id}
```

View a specific declaration which has been previously submitted. Check declaration details and void those which have been submitted in error.

### Example response body

```json
{
  "data": {
    "id": "d0b4a32e-a272-489e-b30a-cb17131457fc",
    "type": "declaration",
    "attributes": {
      "application_id": "ab3a7848-1208-7679-942a-b4a70eed400a",
      "declaration_type": "started",
      "course_identifier": "tte-early-years",
      "declaration_date": "2025-09-15T10:00:00Z",
      "state": "submitted",
      "has_passed": null,
      "statement_id": null,
      "clawback_statement_id": null,
      "lead_provider_name": "Example Institute",
      "ineligible_for_funding_reason": null,
      "delivery_partner_id": "524df095-f9bf-4f9d-ba4c-772545a99e60",
      "delivery_partner_name": "Regional Delivery Partner",
      "created_at": "2025-09-15T10:00:00.000Z",
      "updated_at": "2025-09-15T10:00:00.000Z"
    }
  }
}
```

## Void a declaration

```
POST /api/v1/declarations/{id}/void
```

Void specific declarations which have been submitted in error. A void request must include a `reason` attribute.

Successful requests will return a response body including updates to the declaration `state`, which will become:

* `voided` if it had been `submitted`, `ineligible`, `eligible`, or `payable`
* `awaiting_clawback` if it had been paid

If a provider voids a `completed` declaration, the outcome will be retracted.

### Example request body

```json
{
  "data": {
    "type": "declaration",
    "attributes": {
      "reason": "submitted-in-error"
    }
  }
}
```

### Example response body

```json
{
  "data": {
    "id": "d0b4a32e-a272-489e-b30a-cb17131457fc",
    "type": "declaration",
    "attributes": {
      "application_id": "ab3a7848-1208-7679-942a-b4a70eed400a",
      "declaration_type": "started",
      "course_identifier": "tte-early-years",
      "declaration_date": "2025-09-15T10:00:00Z",
      "state": "voided",
      "has_passed": null,
      "statement_id": "cd3a1234-7308-4879-942a-c4a70ced400a",
      "clawback_statement_id": null,
      "lead_provider_name": "Example Institute",
      "ineligible_for_funding_reason": null,
      "delivery_partner_id": "524df095-f9bf-4f9d-ba4c-772545a99e60",
      "delivery_partner_name": "Regional Delivery Partner",
      "created_at": "2025-09-15T10:00:00.000Z",
      "updated_at": "2025-09-15T10:00:00.000Z"
    }
  }
}
```
