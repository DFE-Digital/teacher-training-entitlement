# View, accept or reject applications

<div class="govuk-inset-text">
  Providers must accept or reject applications before participants start a course and inform applicants of the outcome regardless of whether the application has been accepted or rejected.
</div>

Applications are the central resource in the API. In addition to accepting and rejecting applications, providers use application endpoints to:

* submit declarations (started, completed)
* defer, resume or withdraw participants
* change delivery partner

Providers can **view application data** to find out if applicants:

* have a valid email address
* have a valid teacher reference number (TRN)
* are eligible for funding
* have a funded place

Participants are not able to make multiple applications for the same course. They have however, the ability to change their selected course provider before the application is accepted.


<div class="govuk-inset-text">
While participants can enter different email addresses when applying for training courses, providers will only see the email address associated with a given course application or registration. DfE will share the relevant email address with the relevant course provider.
</div>

## Change of course provider

When a participant changes their Lead Provider from Provider A to Provider B:

* **Provider A** will still be able to view the application, it will however be in read-only mode and no operations will be allowed on it. The application field `unassigned_at` will be set to the date the change occurred.
* **Provider B** will the now view the application, the field `unassigned_at` is set to `null`. The application is fully actionable.

Providers can filter applications by status `unassigned` to find applications that have been reassigned away from them.

## Retrieve multiple applications

```
GET /api/v1/applications
```

Providers can filter results to see more specific or up to date data by adding `cohort`, `participant_id`, `status` and `updated_since` filters to the parameter.

For example: `GET /api/v1/applications?filter[cohort]=2025&filter[status]=pending&filter[updated_since]=2025-11-13T11:21:55Z`

See the ['Retrieve multiple applications' endpoint documentation](/api/docs/v1#/Applications/get_api_v1_applications) for more information.

### Example response body

```json
{
  "data": [
    {
      "id": "d0b4a32e-a272-489e-b30a-cb17131457fc",
      "type": "application",
      "attributes": {
        "course_identifier": "tte-early-years",
        "email": "isabelle.macdonald2@some-school.example.com",
        "email_validated": true,
        "full_name": "Isabelle MacDonald",
        "funding_choice": "school",
        "ineligible_for_funding_reason": null,
        "participant_id": "7a8fef46-3c43-42c0-b3d5-1ba5904ba562",
        "teacher_reference_number": "1234567",
        "teacher_reference_number_validated": true,
        "school_urn": "106286",
        "school_ukprn": "10079319",
        "status": "pending",
        "works_in_school": true,
        "cohort": "2025",
        "eligible_for_funding": true,
        "teacher_catchment": true,
        "teacher_catchment_country": "United Kingdom of Great Britain and Northern Ireland",
        "teacher_catchment_iso_country_code": "GBR",
        "funded_place": null,
        "schedule_identifier": "tte-early-years-autumn",
        "unassigned_at": null,
        "created_at": "2025-09-01T09:00:00.000Z",
        "updated_at": "2025-09-01T09:00:00.000Z"
      }
    }
  ]
}
```

## Retrieve a single application

```
GET /api/v1/applications/{id}
```

See the ['Retrieve a single application' endpoint documentation](/api/docs/v1#/Applications/get_api_v1_applications__id_) for more information.

## Accept an application

```
PUT /api/v1/applications/{id}/accept
```

Providers should accept applications for those they want to enrol onto a course. Providers must inform applicants of the outcome of their successful application.

Reasons to accept applications include (but are not limited to) the participant:

* having funding confirmed
* being suitable for their chosen course
* having relevant support from their school

The request parameter must include the `id` of the corresponding application.

### Example request body

```json
{
  "data": {
    "type": "application",
    "attributes": {
      "funded_place": true
    }
  }
}
```

Successful requests will return a response body including updates to the status attribute.

See the ['Accept an application' endpoint documentation](/api/docs/v1#/Applications/put_api_v1_applications__id__accept) for more information.

## Reject an application

```
PUT /api/v1/applications/{id}/reject
```

Providers should **reject applications** for those they do not want to enrol onto a course.

Providers **must inform applicants** of the outcome of their unsuccessful application.

Reasons to reject applications include (but are not limited to) the participant:

* having been unsuccessful in their application process
* not having secured funding
* wanting to use another provider
* wanting to take on another course
* no longer wanting to take the course

The request parameter must include the `id` of the corresponding application. A `reason` attribute can be included in the request body.

### Example request body

```json
{
  "data": {
    "type": "application",
    "attributes": {
      "reason": "not-eligible"
    }
  }
}
```

Successful requests will return a response body including updates to the `status` attribute.

See the ['Reject an application' endpoint documentation](/api/docs/v1#/Applications/put_api_v1_applications__id__reject) for more information.

## Change funded place value of an application

```
PUT /api/v1/applications/{id}/change-funded-place
```

Providers can update a participant's funding information after an application has been accepted.

It's not possible to change this information if the application has not been accepted.

### Example request body

```json
{
  "data": {
    "type": "application",
    "attributes": {
      "funded_place": true
    }
  }
}
```

Successful requests will return a response body including updates to the `funded_place` attribute.

## Defer a participant

```
PUT /api/v1/applications/{id}/defer
```

A participant can choose to **defer** their course at any time if they plan to resume training at a later date. Providers must notify DfE of this via the API by deferring the application.

<div class="govuk-inset-text">
  Deferred applications have a deadline by which they must be resumed. If the deadline passes without a resume, the application is automatically withdrawn by the system. Providers can detect this by polling applications with <code>filter[updated_since]</code> and checking for status changes.
</div>

Successful requests will return a response body including updates to the application.

### Example request body

```json
{
  "data": {
    "type": "application",
    "attributes": {
      "reason": "bereavement"
    }
  }
}
```

## Resume a participant

```
PUT /api/v1/applications/{id}/resume
```

A participant can **resume** their course if they've previously deferred. Providers must notify DfE of this via the API by resuming the application.

When resuming, the provider must select a target cohort. Available cohorts can be retrieved from `GET /api/v1/cohorts` and must match the application's `course_identifier`. The API validates this — a `400 Bad Request` is returned if the selected cohort's course does not match.

### Example request body

```json
{
  "data": {
    "type": "application",
    "attributes": {
      "schedule_id": "23b4a32e-a272-489e-12oe-cb17131457fc"
    }
  }
}
```

### Retrieving available cohorts

```
GET /api/v1/schedules
```

This endpoint returns active cohorts. Use it to find a compatible cohort when resuming a deferred application.

#### Example response body

```json
{
  "data": [
    {
      "id": "d0b4a32e-a272-489e-b30a-cb17131457fc",
      "type": "schedule",
      "attributes": {
        "course_identifier": "tte-early-years",
        "schedule_identifier": "tte-early-years-spring",
        "cohort": "2026"
      }
    },
    {
      "id": "23b4a32e-a272-489e-12oe-cb17131457fc",
      "type": "schedule",
      "attributes": {
        "course_identifier": "tte-early-years",
        "schedule_identifier": "tte-early-years-autumn",
        "cohort": "2026"
      }
    }
  ]
}
```

## Withdraw a participant

```
PUT /api/v1/applications/{id}/withdraw
```

A participant can choose to **withdraw** from their course at any time. Providers must notify DfE of this via the API by withdrawing the application.

Successful requests will return a response body including updates to the application.

Providers should note that:

* the API will not allow withdrawals for participants who've not had a started declaration submitted against them. If a participant withdraws before a started declaration has been submitted, providers should speak to their contract manager for further advice
* we'll only pay for participants who have had, at a minimum, a started declaration submitted against them
* if a participant is withdrawn later in their course, we'll pay providers for any declarations submitted where the `declaration_date` is before the withdrawal date
* the amount we'll pay depends on which milestones have been reached with declarations submitted before withdrawal

### Example request body

```json
{
  "data": {
    "type": "application",
    "attributes": {
      "reason": "insufficient-capacity-to-undertake-programme"
    }
  }
}
```

## Update an application due to a change in circumstance

There are several reasons why there might be a change in circumstance for an application, including where a participant:

* made a mistake during their application
* selected the wrong course during their application
* wants to take another course instead
* wants to fund their course differently

Where there has been a change in circumstance, providers should:

* reject the application if the application `status` is `pending`
* contact DfE if the application `status` is `accepted`

For example, if a participant registers for a course but then decides to change to another course, the provider should:

1. Reject that participant's application.
2. Ask the participant to re-register on the registration service, entering the correct course details.
3. Accept the new application once it is available via the API.
