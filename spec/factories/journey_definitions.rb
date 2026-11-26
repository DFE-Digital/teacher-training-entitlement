FactoryBot.define do
  factory :journey_definition, class: "Registrations::JourneyDefinition" do
    sequence(:name) { |n| "Registration journey #{n}" }
    sequence(:slug) { |n| "registration-journey-#{n}" }

    initialize_with { Registrations::JourneyDefinition.new(name:, slug:) }
  end

  factory :step_definition, class: "Registrations::StepDefinition" do
    journey_definition
    sequence(:name) { |n| "Registration step #{n}" }
    sequence(:slug) { |n| "registration-step-#{n}" }
    step_class { nil }
    type { nil }
    config { {} }

    initialize_with do
      resolved_step_class = step_class || type&.constantize || Registrations::StepDefinitions::Plain
      Registrations::StepDefinition.new(journey_definition:, step_class: resolved_step_class, name:, slug:, config:)
    end
    after(:build) do |step|
      step.journey_definition.add_step(step) unless step.journey_definition.step_definitions.include?(step)
    end
  end
end
