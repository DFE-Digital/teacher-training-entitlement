# Spike journey entry points and shared funding eligibility

This note focuses on the two spike journeys used to explore composing a journey
from reusable steps. It describes where each URL is routed and how the shared
funding eligibility steps can use different funding rules without changing the
questions or graph.

## Design principles

- **Reuse common presentation.** Simple questions and answers use the shared
  step definitions and registration views. Add a new step class or view only
  when the behaviour or presentation needs to be different.
- **Keep journey configuration in code.** Course names, slugs, identifiers,
  and service classes live in course definitions. The wizard declares which
  steps make up the course journey.
- **Compose journeys declaratively.** A course wizard names its steps and
  transitions in one place. DfE Wizard builds and runs the graph from those
  declarations.
- **Reuse a journey slice without coupling course wizards together.** A course
  can inject a shared partial journey, such as funding eligibility, and specify
  where it joins and rejoins. The course wizard does not need to inherit from
  the shared journey wizard.
- **Keep calculation rules cohesive.** The shared funding journey owns its
  questions and transitions; an injected service owns the eligibility rules.
  The service communicates its result through the agreed state-store key, so a
  course can change its rules without copying or changing the questions.
- **Use execution points for hooks.** Services can run at defined points such
  as `before_show` and `after_update`, allowing work to be attached to the
  relevant step without putting service logic into the graph itself.

This keeps each piece responsible for one concern: course definitions describe
the course, course wizards compose its steps, shared journeys package reusable
sections, and services implement business rules. Dependencies cross those
boundaries through explicit inputs and small contracts, which keeps the pieces
cohesive without making them depend on each other's internal logic.

## Request flow

The routes in `config/routes.rb` send `/registrations/:journey_slug` and its
step routes to `RegistrationsController`. The controller applies the
registration access checks and asks `Registrations::JourneyWizardFactory` for
the wizard matching the journey slug.

`JourneyWizardFactory` maps the course definition to a wizard class. The
wizard's `steps_processor` builds the DfE Wizard graph. Shared setup and
navigation helpers live in `Registrations::BaseJourneyWizard`.

## The two spike journeys

| URL | Course definition | Wizard | Journey outline |
| --- | --- | --- | --- |
| `/registrations/course-one` | `Registrations::Courses::CourseOne` | `Registrations::Journeys::Spikes::CourseOneWizard` | Cheese question → shared funding eligibility journey → check answers. |
| `/registrations/course-two` | `Registrations::Courses::CourseTwo` | `Registrations::Journeys::Spikes::CourseTwoWizard` | Cracker question → shared funding eligibility journey → colour question → check answers. |

The factory mapping is in
`app/wizards/registrations/journey_wizard_factory.rb`. Course metadata is in
`app/wizards/registrations/courses/course_one.rb` and
`app/wizards/registrations/courses/course_two.rb`. Each wizard explicitly
builds its course-specific steps and chooses where the shared journey begins
and rejoins:

- `app/wizards/registrations/journeys/spikes/course_one_wizard.rb`
- `app/wizards/registrations/journeys/spikes/course_two_wizard.rb`

## Injecting the shared funding journey

Both spike wizards call `add_shared_journey` with
`SharedFundingEligibilityJourneyWizard`. They pass the graph, the step to
continue from (`after:`), the step to rejoin (`before:`), and the funding
eligibility implementation:

```ruby
add_shared_journey(
  SharedFundingEligibilityJourneyWizard,
  graph:,
  after: :cheese,
  before: :check_answers,
  funding_eligibility_class: course_definition::FUNDING_ELIGIBILITY_CLASS,
)
```

Course Two uses the same shared journey between `:crackers` and `:colour`.
`BaseJourneyWizard#add_shared_journey` supplies the shared journey with an
`add_node` callback and the wizard's state store. The shared class then adds
its own nodes and graph transitions between the supplied entry and rejoin
steps.

The shared questions and graph live in
`app/wizards/registrations/journeys/spikes/shared_funding_eligibility_journey_wizard.rb`:

1. Do you work in England?
2. Tell us where you work.
3. Select your workplace.
4. Show the funding eligibility result, or ask how the participant will fund
   the course.

## Changing the funding rules independently

`SharedFundingEligibilityJourneyWizard` receives a `funding_eligibility_class:`
when it is added to the graph. It attaches that class as an `after_update`
service to the relevant answers. `BaseJourneyWizard#execute_services` runs the
configured service after the step is saved.

This lets a journey keep the same steps and transitions while changing how
funding eligibility is calculated. Each spike wizard receives its course
definition from `JourneyWizardFactory` through `BaseJourneyWizard`, and passes
that definition's service class into the shared journey. To specialize Course
One, point its course definition constant at a different service; the wizard
will then use it without changing the shared questions or transitions:

```ruby
funding_eligibility_class: Registrations::Courses::CourseOne::FUNDING_ELIGIBILITY_CLASS
```

The injected service should accept `wizard_step:` and implement `call`. The
shared result page and its graph currently read
`state_store["funding_eligibility_result"]`, using the values in
`Registrations::FundingEligibilityConstants`. A replacement service should
write a compatible result there; it can apply different eligibility rules
while preserving the shared page flow.

At present, both course definitions point to the Excellence in Reception
funding eligibility implementation. Each can point to a different service
when its calculation rules diverge.

## Choosing application completion logic

The check-answers steps also take their application creation service from the
injected course definition, using its `APPLICATION_COMPLETION_CLASS` constant.
Excellence in Reception, Course One, and Course Two currently point to the same
`Registrations::ExcellenceInReception::ApplicationCreation` service. A course
can select a different implementation by changing its constant, without
changing the shared funding questions or the wizard's check-answers step.
