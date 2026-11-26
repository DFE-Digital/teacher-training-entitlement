# Registration journeys

Registration journeys are DfE Wizard graphs built in code. Each wizard declares
its nodes, edges, roots and conditional transitions directly. Every screen has
its own concrete class including `DfE::Wizard::Step`; the class holds the
question, answer options, validation and any step-specific behaviour.

## Where to look

- `app/controllers/registrations_controller.rb` maps journey slugs to wizard
  classes and creates the selected course instance.
- `app/wizards/registrations/base_journey_wizard.rb` supplies shared wizard
  setup, URL generation and the `add_shared_wizard` composition hook.
- `app/wizards/registrations/journeys/` contains the journey graphs.
- `app/wizards/registrations/steps/` contains concrete DfE Wizard step classes.
- `app/views/registrations/` contains the shared templates used by those steps.

## Declaring a wizard

A wizard builds a graph with `DfE::Wizard::StepsProcessor::Graph.draw`. The
symbols passed to `add_node`, `root` and `add_edge` are the step IDs used by
DfE Wizard and in the registration URLs.

```ruby
class ExampleWizard < BaseJourneyWizard
  def steps_processor
    @steps_processor ||= DfE::Wizard::StepsProcessor::Graph.draw(self, predicate_caller: state_store) do |graph|
      graph.add_node :start, Steps::Example::Start
      graph.add_node :check_answers, Steps::Example::CheckAnswers
      graph.root :start
      graph.add_edge from: :start, to: :check_answers
    end
  end
end
```

Each node points directly to its step class. There is no intermediate journey
or step-definition layer: the graph is ordinary DfE Wizard configuration and
the step class is the form object rendered for that screen.

## Defining a step

Step classes include `DfE::Wizard::Step`. Shared registration partials are
selected through a class constant, while form attributes and validations use
the normal DfE Wizard step API.

```ruby
module Registrations
  module Steps
    module Example
      class Start
        include DfE::Wizard::Step

        TITLE = "Choose an option"
        PARTIAL = "radio_buttons"
        ATTRIBUTE = :choice
        ANSWER_DISPLAY_NAME = "Choice"

        attribute ATTRIBUTE, :string
        validates ATTRIBUTE, presence: { message: "Select an option" }

        def self.permitted_params = [ATTRIBUTE]

        def self.answer_options
          [{ name: "First option", value: "first" }, { name: "Second option", value: "second" }]
        end
      end
    end
  end
end
```

The partial is one of the registration templates such as `plain`,
`radio_buttons`, `checkboxes`, `choose_institution`, `html_partial` or
`check_answers`. A step can provide `TEXTS` or `PARTIAL_NAME` when its screen
needs extra content. Dynamic answer labels can be returned by
`display_answer_value(value:)`.

For example, `CourseStartDate` builds its radio options from the current
course's registerable cohorts. It saves the chosen option's friendly label
with the state so Check Answers can display it later.

## Composing a shared journey

`add_shared_wizard` lets a course wizard compose a section from another wizard
without inheriting from it. The shared wizard receives the host graph and the
step IDs where the section should join and rejoin. Its `add_to_graph` method
adds concrete DfE Wizard step classes and connects the graph edges.

```ruby
add_shared_wizard(
  SharedFundingJourneyWizard.new(
    graph:,
    after: :course_question,
    before: :check_answers,
  ),
)
```

This keeps shared questions and their transitions together while the course
wizard stays responsible for its own surrounding flow. The existing examples
are `SharedFavouritePetAndSportJourneyWizard` and
`SharedSendFundingEligibilityJourneyWizard` under
`app/wizards/registrations/journeys/spikes/`.

## Services and conditional transitions

Use graph predicates for navigation based on the wizard state store. Put
business calculations in a service and call it from the step lifecycle hook
that matches the operation, such as `after_update`. The course supplies
course-specific funding eligibility and application creation service classes.

Keeping graph declarations, step form behaviour and business calculations in
their respective classes makes each journey explicit while still allowing
shared sections and shared presentation.
