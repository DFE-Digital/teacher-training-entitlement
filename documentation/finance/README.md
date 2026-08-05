# Finance — Overview

The finance domain is set to give some flexibility to create contract that suits DfE needs for a course. This domain allows values to be set as contract of overall while keeping the ability to 
set some changes per academic year along with some control at the course cohort level.

To determine the value of a contractual field you merge:
- Default contract
- Academic year contract
- CourseCohorProvider contract


## Contract

A contract is computed set of values defined at 3 levels: 
- default level
- academic year level
- course cohort level

The computation is a merge operation: 
`default values merged with academic_year values merged with course_cohort values`

### Default contract

The contract is setup in with the `ContractYear` with the academic_year field left null.
Whatever value are set at this level will apply to the statement calculation unless a field is amended at lower level (ie Academic year level and or course cohort level)

Example:
we can set a Lead provider a set recruitment_target 100 year on year for all their course cohorts
```
ContractYear.create(
  lead_provider:,
  course:,
  recruitment_target: 100,
  academic_year: nil,
)
```

### Academic year specifics

The Lead provider contract can be amended per academic year.
With the earlier example the Lead provider can have recruitment_target of 200 for the academic year 2026. For the years prior and after the recruitment_target is 100.

```
ContractYear.create(
  lead_provider:,
  course:,
  recruitment_target: 200,
  academic_year: 2026,
)
```

### CourseCohort specifics

The Lead provider contract can also be amended to have specific value for each course cohort in an academic year.
The model `CourseCohortProvider` allows to setup amendments at course cohort level
```
CourseCohortProvider.create(
  course_cohort: first_course_cohort,
  lead_provider:,
  recruitment_target: 150,
)

CourseCohortProvider.create(
  course_cohort: second_course_cohort,
  lead_provider:,
  recruitment_target: 50,
)
```


## Milestone

A milestone defines what declaration is expected, when it is expected (acceptance window), in what order relative to other declarations and how much the declaration is worth.

### Acceptance window

It is defined as offsets relative to the course_cohort.training_start_date
Example for a 30 days acceptance windows
```
acceptance_window_start_date = course_cohort.training_start_date + 90 days
acceptance_window_end_date = course_cohort.training_start_date + 120 days

```


## Declaration

A declaration records on event in the life-cycle of a teacher's training journey; started, retained, completed training events.
A declaration may also have a financial implication as it represents a financial statement entry which has an amount. That amount may be:
- positive (100),  DfE will pay that amount to Lead provider
- null     (0),    no payment attached to this declaration
- negative (-100), only for clawback declaration (details below)

### Amount

The amount is defined as a percentage of the contract.teacher_funding by the associated milestone percentage. Here contract is the computed set of values described in the contract section.

```
declaration.amount = contract.teacher_funding * milestone.percentage (0.6)
```


### ClawbackDeclaration

A clawback declaration is a specific type of declaration that gets created internally as a knock on effect to voiding a paid declaration. 
Both paid declaration and clawback declaration links to each other and a clawaback declaration is an exact replica of its paid declaration with negative amount.


## [TODO] Uplift Incentives


## Statement

A statement is a list of declarations and adjustments.

### Core formula

The total of the statement is the simple sum of all declarations added with the sum of all manual adjustments.

> `statement.total = Σ declarations.amount + Σ adjustments.amount`

This core formula can be apply to groups such as:
- milestones
- course cohorts
