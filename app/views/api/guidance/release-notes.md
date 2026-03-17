# Release notes

If you have any questions or comments about these notes, please contact DfE via Microsoft Teams or email.

<!-- ## 1 June 2026 -->

<!-- ### API Launch <strong class="govuk-tag govuk-tag--green">PRODUCTION</strong> -->

<!-- The API V1 is made live for providers. -->

## 17 March 2026

### API Beta Changes <strong class="govuk-tag govuk-tag--yellow">SANDBOX</strong>

The API has been updated based on the beta specification. Key changes:

**Applications are now the central resource.** All lifecycle actions have moved to applications:

* Declarations are now submitted via `POST /applications/{id}/declarations/started` and `POST /applications/{id}/declarations/completed` (previously `POST /participant-declarations`)
* Defer, resume and withdraw are now application actions (previously on `/participants/{id}/*`)
* New `change-delivery-partner` action on applications

**New endpoints:**

* `GET /cohorts` — returns active cohorts, used when resuming a deferred application

**New application field:**

* `unassigned_at` — indicates when an application has been reassigned to another provider (application becomes read-only for the previous provider)

**Declarations resource updated:**

* Renamed from `/participant-declarations` to `/declarations`
* Now read-only (query and void only)
* Void changed from PUT to POST and now accepts a `reason` attribute
* New filters: `application_id`, `declaration_type`
* Type renamed from `participant-declaration` to `declaration`

**Participants are now read-only.** All write operations removed.

**Removed endpoints:**

* `PUT /participants/{id}/change-schedule` — replaced by deferral deadline policy and cohort selection on resume

**Deferral policy change:**

* Deferred applications now have a deadline. If not resumed in time, the application is automatically withdrawn.

-----

## 1 March 2026

### API Launch <strong class="govuk-tag govuk-tag--yellow">SANDBOX</strong>

The API V1 is made available for providers for their integration work.


-----

### Provider technical support

Contact us via the engagement and policy leads if you want to discuss your integration and technical plans in more detail.

Our team are happy to host technical workshops with providers to ensure this integration runs smoothly.

