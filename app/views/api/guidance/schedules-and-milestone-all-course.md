# Schedules and milestone dates



DfE pays providers in line with agreed contractual schedules and training criteria. Providers are paid based on how much time they spend supporting participants.

Providers must [submit declarations](/api/guidance/how-to-guides/submit-view-and-void-declarations) against applications ahead of milestone dates (deadlines) to ensure payments are made for a given milestone.


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
      <th scope="row" class="govuk-table__header">Schedule</th>
      <td class="govuk-table__cell">The timeframe in which a participant starts a particular course, which determines milestone dates</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header">Milestone</th>
      <td class="govuk-table__cell">Contractual retention periods during which providers must submit relevant declarations evidencing training delivery and participant retention</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header">Milestone dates</th>
      <td class="govuk-table__cell">The deadline date a valid declaration can be made for a given milestone in order for DfE to be liable to make a payment the following month. Milestone dates are dependent on the participant's schedule</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header">Milestone period</th>
      <td class="govuk-table__cell">The period of time between the milestone start date and deadline date</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header">Output payment</th>
      <td class="govuk-table__cell">The sum of money paid by DfE to providers per valid declaration</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header">Payment date</th>
      <td class="govuk-table__cell">The date DfE will make payment for valid declarations submitted by providers for a given milestone</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header">Milestone validation</th>
      <td class="govuk-table__cell">The API's process to validate declarations submitted by providers for participants in standard training schedules</td>
    </tr>
  </tbody>
</table>

## Schedules and dates

A default schedule can last 2 terms.

For the 2026 cohort, the schedule is:

* Reception July

For each of the milestones a provider is supporting a participant, DfE will pay the corresponding output payment according to valid declarations submitted.

Declarations submitted for participants will be validated (accepted or rejected) against the milestone dates.

Contact DfE contract managers via email for additional support or information.

### 2026 cohort

Participants starting their training on or before May 2025 as part of this cohort, will be on the following schedules.

Schedule identifiers:

* `reception-july`

<table class="govuk-table">
  <thead class="govuk-table__head">
    <tr class="govuk-table__row">
      <th scope="col" class="govuk-table__header">Milestone</th>
      <th scope="col" class="govuk-table__header">Milestone date</th>
      <th scope="col" class="govuk-table__header">Declaration type</th>
      <th scope="col" class="govuk-table__header">Payment date</th>
    </tr>
  </thead>
  <tbody class="govuk-table__body">
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header">Participant start</th>
      <td class="govuk-table__cell">30 October 2026</td>
      <td class="govuk-table__cell">started</td>
      <td class="govuk-table__cell">30 November 2026</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header">Participant completion</th>
      <td class="govuk-table__cell">30 March 2027</td>
      <td class="govuk-table__cell">completed</td>
      <td class="govuk-table__cell">30 April 2027</td>
    </tr>
  </tbody>
</table>


## Validating declarations against milestones

Declarations submitted against applications are subject to milestone validation.
The API will perform milestone validation to reject a declaration if it is not submitted for the correct milestone.

If a declaration is submitted in a later milestone period (i.e. a started declaration submitted during a later milestone period), then it will be validated and paid at the next milestone payment.
