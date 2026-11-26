# Spike journey entry points and shared composition

The registrations controller maps journey slugs to wizard classes in
`WIZARD_COURSE_MAP`. The course identifier is also used as the journey slug for
course journeys, so a request such as `/registrations/course-one/cheese` loads
`Registrations::Journeys::Spikes::CourseOneWizard` and its `:cheese` step.

## Spike journeys

| URL | Wizard | Journey outline |
| --- | --- | --- |
| `/registrations/course-one` | `Registrations::Journeys::Spikes::CourseOneWizard` | Cheese → favourite pet → favourite sport → funding result → check answers |
| `/registrations/course-two` | `Registrations::Journeys::Spikes::CourseTwoWizard` | Crackers → favourite pet → favourite sport → funding result → colour → check answers |

The course wizards live in `app/wizards/registrations/journeys/spikes/`. Their
`steps_processor` methods declare the DfE Wizard graph and name each concrete
step class explicitly. The concrete step classes are under
`app/wizards/registrations/steps/spikes/`.

## Shared wizard composition

Course One and Course Two both compose
`SharedFavouritePetAndSportJourneyWizard`. The host wizard passes its graph and
the IDs of the entry and rejoin steps:

```ruby
add_shared_wizard(
  SharedFavouritePetAndSportJourneyWizard.new(
    graph:,
    after: :cheese,
    before: :check_answers,
  ),
)
```

Course Two uses `after: :crackers` and `before: :colour`. The shared wizard's
`add_to_graph` method adds its own concrete `DfE::Wizard::Step` classes and
connects the nodes between those host steps. `BaseJourneyWizard#add_shared_wizard`
is the small composition hook that invokes it. This keeps the shared section
reusable without making either course wizard inherit from it.

The shared question step runs the course's funding eligibility service. That
service reads the shared answers from the state store and writes
`funding_eligibility_result`; the shared result partial displays the result.
The questions and calculation stay separate, so the calculation can change
through the course's service class without changing the shared step classes.

## Application creation and funding services

The course selects its funding eligibility and application creation services
through methods on the course model. The check-answers step invokes the
application creation service in its `after_update` hook. Shared question steps
invoke the funding service at their `after_update` hook. These service calls
are part of the normal DfE Wizard lifecycle and do not require a separate
step-definition or execution DSL.
