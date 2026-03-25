# Data states

## Concepts and definitions

<table class="govuk-table">
  <thead class="govuk-table__head">
    <tr class="govuk-table__row">
      <th scope="col" class="govuk-table__header">Concept</th>
      <th scope="col" class="govuk-table__header">Definition</th>
    </tr>
  </thead>
  <tbody class="govuk-table__body">
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>application</code></th>
      <td class="govuk-table__cell">The application a person makes to be trained on a course. Applications are the central resource — all lifecycle actions (declarations, deferrals, withdrawals, resumes) are performed against applications</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>participant</code></th>
      <td class="govuk-table__cell">A person registered for a course. Participants are read-only — use application endpoints for all actions</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>cohort</code></th>
      <td class="govuk-table__cell">A combination of course, schedule and academic year. Active cohorts are used when resuming a deferred application</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>schedule</code></th>
      <td class="govuk-table__cell">The expected timeframe in which a participant will complete their course. Schedules include defined <a href="/api/guidance/schedules-and-milestone-dates" class="govuk-link">milestone dates</a> against which DfE validates the declarations submitted by providers</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>course_identifier</code></th>
      <td class="govuk-table__cell">The course a participant applies for and is registered for</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>outcome</code></th>
      <td class="govuk-table__cell">The assessment result a participant achieves at the end of a course. Outcomes are automatically created when a completed declaration is submitted</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>declaration</code></th>
      <td class="govuk-table__cell">The notification submitted by providers via the API to trigger output payments from DfE. Declarations are submitted against applications where there is evidence of a participant's engagement in training for a given milestone period</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>statement</code></th>
      <td class="govuk-table__cell">A record of output payments (based on declarations), service fees and any adjustments DfE may pay lead providers at the end of a contractually agreed payment period. Statements sent to providers by DfE at the end of milestone periods can be used for invoicing purposes</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>funded place</code></th>
      <td class="govuk-table__cell">The way for DfE and providers to identify participants who are eligible for funding and for whom there is funding available</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>funding cap</code></th>
      <td class="govuk-table__cell">The maximum number of places each provider can offer per that DfE will pay for an academic year</td>
    </tr>
  </tbody>
</table>

## Application data states

This API uses a `state` model to reflect the participant journey, meet contractual requirements for how providers should report participants' training and how DfE will pay for this training.

Application states are defined by the `status` attribute.

An application's status value will determine whether a provider can:

* accept or reject applications

* submit a declaration. For example, notifying DfE that a participant has started their training

* defer, resume or withdraw a participant

<table class="govuk-table">
  <caption class="govuk-table__caption govuk-table__caption--m">Application status values</caption>
  <thead class="govuk-table__head">
    <tr class="govuk-table__row">
      <th scope="col" class="govuk-table__header">Status</th>
      <th scope="col" class="govuk-table__header govuk-table__header">Definition</th>
      <th scope="col" class="govuk-table__header govuk-table__header">What providers can do</th>
    </tr>
  </thead>
  <tbody class="govuk-table__body">
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>pending</code></th>
      <td class="govuk-table__cell govuk-table__cell">Applications which have been made for a course</td>
      <td class="govuk-table__cell govuk-table__cell">Accept or reject applications</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>accepted</code></th>
      <td class="govuk-table__cell govuk-table__cell">Applications which have been accepted by a provider</td>
      <td class="govuk-table__cell govuk-table__cell">Submit declarations, defer, withdraw, change delivery partner</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>rejected</code></th>
      <td class="govuk-table__cell govuk-table__cell">Applications which have been rejected by a provider, or which have been accepted by another provider</td>
      <td class="govuk-table__cell govuk-table__cell">No action required</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>started</code></th>
      <td class="govuk-table__cell govuk-table__cell">Applications where a started declaration has been submitted</td>
      <td class="govuk-table__cell govuk-table__cell">Submit completed declaration, defer, withdraw</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>deferred</code></th>
      <td class="govuk-table__cell govuk-table__cell">Applications where the participant has deferred training. Deferred applications have a deadline — if not resumed in time, they are automatically withdrawn</td>
      <td class="govuk-table__cell govuk-table__cell">Resume the application by selecting a target cohort from <code>GET /api/v1/cohorts</code></td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>withdrawn</code></th>
      <td class="govuk-table__cell govuk-table__cell">Applications where the participant has withdrawn from training, either manually or automatically after a deferral deadline</td>
      <td class="govuk-table__cell govuk-table__cell">Submit declarations if the <code>declaration_date</code> is backdated to before the withdrawal date</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>completed</code></th>
      <td class="govuk-table__cell govuk-table__cell">Applications where a completed declaration has been submitted</td>
      <td class="govuk-table__cell govuk-table__cell">View only</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>unassigned</code></th>
      <td class="govuk-table__cell govuk-table__cell">Applications which have been reassigned to another provider. The <code>unassigned_at</code> field shows when the reassignment occurred</td>
      <td class="govuk-table__cell govuk-table__cell">View only (read-only for the previous provider)</td>
    </tr>
  </tbody>
</table>

## Participant data states

Participant states are defined by the `training_status` attribute within each enrolment.

Participants are read-only. To change a participant's training status, use the corresponding application endpoint (defer, resume, withdraw).

<table class="govuk-table">
  <caption class="govuk-table__caption govuk-table__caption--m">Training status values</caption>
  <thead class="govuk-table__head">
    <tr class="govuk-table__row">
      <th scope="col" class="govuk-table__header">Training status</th>
      <th scope="col" class="govuk-table__header govuk-table__header">Definition</th>
      <th scope="col" class="govuk-table__header govuk-table__header">What providers can do</th>
    </tr>
  </thead>
  <tbody class="govuk-table__body">
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>active</code></th>
      <td class="govuk-table__cell govuk-table__cell">Participants currently in training</td>
      <td class="govuk-table__cell govuk-table__cell">Submit declarations and manage the application (defer, withdraw)</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>deferred</code></th>
      <td class="govuk-table__cell govuk-table__cell">Participants who've deferred training</td>
      <td class="govuk-table__cell govuk-table__cell">Resume the application via <code>PUT /api/v1/applications/{id}/resume</code></td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>withdrawn</code></th>
      <td class="govuk-table__cell govuk-table__cell">Participants who have withdrawn from training</td>
      <td class="govuk-table__cell govuk-table__cell">Submit declarations for withdrawn participants if the <code>declaration_date</code> is backdated to before the withdrawal date</td>
    </tr>
  </tbody>
</table>

## Declaration data states

Declaration states are defined by the `state` attribute.

Providers must submit declarations against applications to confirm a participant has engaged in training within a given milestone period. A declaration's `state` value will reflect if and when DfE will pay providers for the training delivered.

<table class="govuk-table">
  <caption class="govuk-table__caption govuk-table__caption--m">Declaration status values</caption>
  <thead class="govuk-table__head">
    <tr class="govuk-table__row">
      <th scope="col" class="govuk-table__header">State</th>
      <th scope="col" class="govuk-table__header govuk-table__header">Definition</th>
      <th scope="col" class="govuk-table__header govuk-table__header">What providers can do</th>
    </tr>
  </thead>
  <tbody class="govuk-table__body">
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>submitted</code></th>
      <td class="govuk-table__cell govuk-table__cell">A declaration associated with to a participant who has not yet been confirmed to be eligible for funding</td>
      <td class="govuk-table__cell govuk-table__cell">View and void</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>eligible</code></th>
      <td class="govuk-table__cell govuk-table__cell">A declaration associated with a participant who has been confirmed to be eligible for funding</td>
      <td class="govuk-table__cell govuk-table__cell">View and void</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>ineligible</code></th>
      <td class="govuk-table__cell govuk-table__cell">A declaration associated with a participant who is not eligible for funding or a duplicate submission for a given participant</td>
      <td class="govuk-table__cell govuk-table__cell">View and void</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>payable</code></th>
      <td class="govuk-table__cell govuk-table__cell">A declaration that has been approved and is ready for payment by DfE</td>
      <td class="govuk-table__cell govuk-table__cell">View and void</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>voided</code></th>
      <td class="govuk-table__cell govuk-table__cell">A declaration that has been retracted by a provider</td>
      <td class="govuk-table__cell govuk-table__cell">View</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>paid</code></th>
      <td class="govuk-table__cell govuk-table__cell">A declaration that has been paid for by DfE</td>
      <td class="govuk-table__cell govuk-table__cell">View and void</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>awaiting_clawback</code></th>
      <td class="govuk-table__cell govuk-table__cell">A <code>paid</code> declaration that has since been voided by a provider</td>
      <td class="govuk-table__cell govuk-table__cell">View</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>clawed_back</code></th>
      <td class="govuk-table__cell govuk-table__cell">An <code>awaiting_clawback</code> declaration that has since had its value deducted from payment by DfE to a provider</td>
      <td class="govuk-table__cell govuk-table__cell">View</td>
    </tr>
  </tbody>
</table>
