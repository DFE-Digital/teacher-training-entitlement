# Spike journey entry points and shared journey composition

This note focuses on the two spike journeys used to explore composing a journey
from reusable steps. It describes where each URL is routed and distinguishes
the shared question journeys currently used by those wizards from the separate
shared funding journey that supports injected eligibility rules.

## Design principles

- **Reuse common presentation.** Simple questions and answers use the shared
  step definitions and registration views. Add a new step class or view only
  when the behaviour or presentation needs to be different.
- **Keep journey configuration in code.** Course identifiers and service
  selection logic live on the `Course` model; the course record supplies its
  display name. The wizard declares which steps make up the course journey.
- **Compose journeys declaratively.** A course wizard names its steps and
  transitions in one place. DfE Wizard builds and runs the graph from those
  declarations.
- **Reuse a journey slice without coupling course wizards together.** A course
  can inject a shared partial journey, such as funding eligibility, and specify
  where it joins and rejoins. The course wizard does not need to inherit from
  the shared journey wizard.
- **Keep calculation rules cohesive.** `SharedFundingEligibilityJourneyWizard`
  accepts an eligibility service class, keeping its questions and transitions
  separate from the calculation. The current Course One and Course Two
  journeys use a different shared question journey, described below.
- **Use execution points for hooks.** Services can run at defined points such
  as `before_show` and `after_update`, allowing work to be attached to the
  relevant step without putting service logic into the graph itself.

This keeps each piece responsible for one concern: the `Course` model exposes
course identity and service selection, course wizards compose steps, shared
journeys package reusable sections, and services implement business rules.
Dependencies cross those boundaries through explicit inputs and small
contracts, which keeps the pieces cohesive without making them depend on each
other's internal logic.

## Request flow

The routes in `config/routes.rb` send `/registrations/:journey_slug` and its
step routes to `RegistrationsController`. The controller applies the
registration access checks and asks `Registrations::JourneyWizardFactory` for
the wizard matching the journey slug.

`JourneyWizardFactory` maps course identifiers to wizard classes and loads the
matching `Course` record. The wizard's `steps_processor` builds the DfE Wizard
graph. Shared setup and navigation helpers live in
`Registrations::BaseJourneyWizard`.

## The two spike journeys

| URL | Course | Wizard | Journey outline |
| --- | --- | --- | --- |
| `/registrations/course-one` | `Course` with identifier `course-one` | `Registrations::Journeys::Spikes::CourseOneWizard` | Cheese question → favourite pet and sport questions → funding result → check answers. |
| `/registrations/course-two` | `Course` with identifier `course-two` | `Registrations::Journeys::Spikes::CourseTwoWizard` | Cracker question → favourite pet and sport questions → funding result → colour question → check answers. |

The factory mapping is in
`app/wizards/registrations/journey_wizard_factory.rb`. Course identifiers and
service-selection methods are in `app/models/course.rb`. Each wizard explicitly
builds its course-specific steps and chooses where the shared journey begins
and rejoins:

- `app/wizards/registrations/journeys/spikes/course_one_wizard.rb`
- `app/wizards/registrations/journeys/spikes/course_two_wizard.rb`

## Shared questions used by the two course wizards

Both course wizards call `add_shared_journey` with
`SharedFavouritePetAndSportJourneyWizard`. They pass the graph, the step to
continue from (`after:`), and the step to rejoin (`before:`):

```ruby
add_shared_journey(
  SharedFavouritePetAndSportJourneyWizard,
  graph:,
  after: :cheese,
  before: :check_answers,
)
```

Course Two uses the same shared journey between `:crackers` and `:colour`.
`BaseJourneyWizard#add_shared_journey` supplies the shared journey with an
`add_node` callback and the wizard's state store. The shared class then adds
its own nodes and graph transitions between the supplied entry and rejoin
steps.

The shared questions and graph live in
`app/wizards/registrations/journeys/spikes/shared_favourite_pet_and_sport_journey_wizard.rb`:

1. What's your favourite pet?
2. What's your favourite sport?
3. Show the funding eligibility result.

This shared class currently attaches
`Registrations::Spikes::FavouriteThingsFundingEligibility` directly. The
Course One and Course Two wizards pass `course.funding_eligibility_service_class`
when composing it, but the shared class does not currently use that argument.
Changing the course's service method therefore does not change this shared
journey's funding calculation yet.

## Injecting funding rules into a shared journey

`SharedFundingEligibilityJourneyWizard` in
`app/wizards/registrations/journeys/spikes/shared_funding_eligibility_journey_wizard.rb`
accepts `funding_eligibility_class:` and attaches it as an `after_update`
service to its relevant steps. `BaseJourneyWizard#execute_services` runs the
configured service after the step is saved. This allows a wizard to reuse that
journey's questions and transitions while supplying a different calculation
service. For example:

```ruby
add_shared_journey(
  SharedFundingEligibilityJourneyWizard,
  graph:,
  after: :cheese,
  before: :check_answers,
  funding_eligibility_class: Registrations::ExcellenceInReception::FundingEligibility,
)
```

The injected service must accept `wizard_step:` and implement `call`. It should
write a compatible result to
`state_store["funding_eligibility_result"]`, using values from
`Registrations::FundingEligibilityConstants`. The result page and graph then
continue to work with the new rules. This injection point is implemented, but
`SharedFundingEligibilityJourneyWizard` currently has no call sites in the
course wizards.

The `Course#funding_eligibility_service_class` method currently returns the
favourite-pet-and-sport service for both spike course identifiers and the
course-specific service for Excellence in Reception and SEND.

## Choosing application completion logic

The check-answers steps take their application creation service from
`Course#application_creation_service_class_name`. Course One and Course Two
currently use `Registrations::Spikes::ApplicationCreation`; Excellence in
Reception and SEND use their own service classes. A course can select a
different implementation in `Course` without changing its wizard's
check-answers step.
