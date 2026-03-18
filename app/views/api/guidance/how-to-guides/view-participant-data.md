# View participant data

Participants are read-only in the API. Use participant endpoints to look up a person and view their enrolments across providers and cohorts.

To update participant training status (defer, resume, withdraw), use the corresponding [application endpoints](/api/guidance/how-to-guides/view-accept-or-reject-applications).

## Retrieve multiple participants

```
GET /api/v1/participants
```

<div class="govuk-inset-text">
Providers can filter results by adding updated_since filters to the parameter. For example: <code>GET /api/v1/participants?filter[updated_since]=2025-11-13T11:21:55Z</code>
</div>

Providers can also filter by `training_status`. For example: `GET /api/v1/participants?filter[training_status]=active`

For more detailed information, see the ['Retrieve multiple participants' endpoint documentation](/api/docs/v1#/Participants/get_api_v1_participants).

### Example response body

```json
{
  "data": [
    {
      "id": "d0b4a32e-a272-489e-b30a-cb17131457fc",
      "type": "participant",
      "attributes": {
        "full_name": "Isabelle MacDonald",
        "teacher_reference_number": "1234567",
        "updated_at": "2025-09-15T10:30:00.000Z",
        "enrolments": [
          {
            "email": "isabelle.macdonald2@some-school.example.com",
            "course_identifier": "tte-early-years",
            "schedule_identifier": "tte-reception-autumn",
            "cohort": "2025",
            "application_id": "db3a7848-7308-4879-942a-c4a70ced400a",
            "eligible_for_funding": true,
            "training_status": "active",
            "school_urn": "106286",
            "withdrawal": null,
            "deferral": null,
            "created_at": "2025-09-01T09:00:00.000Z",
            "funded_place": true
          }
        ],
        "participant_id_changes": []
      }
    }
  ]
}
```

## Retrieve a single participant's data

```
GET /api/v1/participants/{id}
```

For more detailed information, see the ['Retrieve a single participant' endpoint documentation](/api/docs/v1#/Participants/get_api_v1_participants__id_).

## Retrieve outcomes

```
GET /api/v1/outcomes
```

Outcomes are created automatically when providers submit `completed` declarations with the `has_passed` attribute.

Providers can filter results by `application_id`. For example: `GET /api/v1/outcomes?filter[application_id]=db3a7848-7308-4879-942a-c4a70ced400a`

### Example response body

```json
{
  "data": [
    {
      "id": "d0b4a32e-a272-489e-b30a-cb17131457fc",
      "type": "outcome",
      "attributes": {
        "state": "completed",
        "completion_date": "2026-06-30T00:00:00+00:00",
        "application_id": "db3a7848-7308-4879-942a-c4a70ced400a",
        "created_at": "2026-06-30T10:00:00.000Z",
        "updated_at": "2026-06-30T10:00:00.000Z"
      }
    }
  ]
}
```
