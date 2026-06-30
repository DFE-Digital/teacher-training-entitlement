[< Back to docs](../README.md)

# Integrations

The Teacher Training Entitlement service connects to three external services.
Each integration is covered by its own detail page (linked below), which
documents the contract, the data flows, and any operational notes.

---

## [GOV.UK One Login](./govuk-one-login.md)

Provides participant authentication and identity verification.

The participant signs in via GOV.UK One Login at the verified-identity level.
The service then calls the **Teacher Record Service (TRS)** to match the
verified identity to a Teacher Reference Number (TRN). Participants without a
TRN — such as Further Education (FE) teachers or those trained outside the UK —
follow an assisted-verification path.

**What the detail page covers:** OIDC flow, TRN acquisition via the TRS API,
TeacherAuth middleware, and assisted-verification handling.

**Legacy source:** [`docs/trn.md`](../trn.md)

---

## [GOV.UK Notify](./govuk-notify.md)

Sends all service-generated email notifications.

The service uses a single GOV.UK Notify template and populates it with dynamic
personalisation fields at send time. Emails are triggered by application state
transitions (submission, deferral, withdrawal, declaration receipt) and are
tracked via the Notify API for delivery status.

**What the detail page covers:** template ID, personalisation fields,
send-email lifecycle, idempotency guarantees, and troubleshooting failed sends.

**Legacy source:** [`docs/sending_emails.md`](../sending_emails.md)

---

## [GIAS (Get Information About Schools)](./govuk-gias.md)

Imports establishment data used in eligibility checks.

A daily scheduled job fetches school and local-authority data from the Azure-
hosted edubase API (the GIAS dataset). The imported data powers school-type
lookups and eligibility decisions during registration — for example, checking
that a participant works at an eligible state-funded institution.

**What the detail page covers:** import schedule, data model of imported
fields, error-handling strategy, idempotent re-import, and manual re-run
procedure.

---

## Related

- [Service data model](../data_model.md) — how imported GIAS records relate to
  applications and participants.
