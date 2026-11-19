namespace :registration_journeys do
  desc "Delete and rebuild registration journeys"
  task rebuild: :environment do
    Registrations::BuildRegistrationJourneys.new.call
  end

  desc "Delete all"
  task delete_all: :environment do
    RegistrationJourney.destroy_all
  end

  desc "Build the registration journey used to demonstrate step types in the documentation"
  task documentation_example: :environment do
    puts "Building #{Registrations::DocumentationExample::RegistrationJourneyBuilder::SLUG}"
    Registrations::DocumentationExample::RegistrationJourneyBuilder.new.call
  end

  desc "Build a minimal registration journey to demonstrate branching"
  task branching_example: :environment do
    RegistrationJourney.transaction do
      registration_journey = RegistrationJourney.find_or_initialize_by(slug: "branching-example", name: "Branching Example")
      registration_journey.registration_steps.destroy_all if registration_journey.persisted?

      create_step = lambda do |**attributes|
        Registrations::Steps::Create.new(registration_journey:, **attributes).call
      end

      choice = create_step.call(
        name: "Choose a path",
        slug: "choose-a-path",
        state_store_key: "path_choice",
        step_class: RegistrationSteps::RadioButtons,
      )
      path_a = create_step.call(
        name: "Path A",
        slug: "path-a",
        step_class: RegistrationSteps::Plain,
        previous_step_id: choice.id,
      )
      path_b = create_step.call(
        name: "Path B",
        slug: "path-b",
        step_class: RegistrationSteps::Plain,
        previous_step_id: choice.id,
      )
      shared_step = create_step.call(
        name: "Shared step",
        slug: "shared-step",
        step_class: RegistrationSteps::Plain,
      )
      create_step.call(
        name: "Check answers",
        slug: "check-answers",
        step_class: RegistrationSteps::CheckAnswers,
        previous_step_id: shared_step.id,
      )

      choice.set_answers!(
        answers: [
          { name: "Take path A", value: "path_a", next_step_id: path_a.id },
          { name: "Take path B", value: "path_b", next_step_id: path_b.id },
        ],
      )
      choice.update!(branch_join_step: shared_step)
      choice.add_text!(text: "Each answer leads to a different step, then both paths rejoin.", text_class: "govuk-body")
      path_a.add_text!(text: "You took path A.", text_class: "govuk-body")
      path_b.add_text!(text: "You took path B.", text_class: "govuk-body")
      shared_step.add_text!(text: "Both paths lead here.", text_class: "govuk-body")

      puts "Built registration journey: #{registration_journey.slug}"
    end
  end

  desc "Build a nested registration journey to demonstrate branch joins"
  task nested_branching_example: :environment do
    RegistrationJourney.transaction do
      registration_journey = RegistrationJourney.find_or_initialize_by(slug: "nested-branching-example")
      registration_journey.registration_steps.destroy_all if registration_journey.persisted?
      registration_journey.update!(name: "Nested Branching Example")
      create_step = lambda do |**attributes|
        Registrations::Steps::Create.new(registration_journey:, **attributes).call
      end

      outer_choice = create_step.call(
        name: "Choose an outer path",
        slug: "choose-an-outer-path",
        state_store_key: "outer_path_choice",
        step_class: RegistrationSteps::RadioButtons,
      )
      outer_path_a = create_step.call(
        name: "Outer path A",
        slug: "outer-path-a",
        step_class: RegistrationSteps::Plain,
        previous_step_id: outer_choice.id,
      )
      inner_choice = create_step.call(
        name: "Choose an inner path",
        slug: "choose-an-inner-path",
        state_store_key: "inner_path_choice",
        step_class: RegistrationSteps::RadioButtons,
        previous_step_id: outer_path_a.id,
      )
      inner_path_a = create_step.call(
        name: "Inner path A",
        slug: "inner-path-a",
        step_class: RegistrationSteps::Plain,
        previous_step_id: inner_choice.id,
      )
      inner_path_b = create_step.call(
        name: "Inner path B",
        slug: "inner-path-b",
        step_class: RegistrationSteps::Plain,
        previous_step_id: inner_choice.id,
      )
      inner_join = create_step.call(
        name: "Inner paths rejoin",
        slug: "inner-join",
        step_class: RegistrationSteps::Plain,
        previous_step_id: inner_path_a.id,
      )
      after_inner_join = create_step.call(
        name: "Continue on outer path A",
        slug: "continue-on-outer-path-a",
        step_class: RegistrationSteps::Plain,
        previous_step_id: inner_join.id,
      )
      outer_path_b = create_step.call(
        name: "Outer path B",
        slug: "outer-path-b",
        step_class: RegistrationSteps::Plain,
        previous_step_id: outer_choice.id,
      )
      outer_join = create_step.call(
        name: "Outer paths rejoin",
        slug: "outer-join",
        step_class: RegistrationSteps::Plain,
      )
      create_step.call(
        name: "Check answers",
        slug: "check-answers",
        step_class: RegistrationSteps::CheckAnswers,
        previous_step_id: outer_join.id,
      )

      outer_choice.set_answers!(
        answers: [
          { name: "Take outer path A", value: "outer_a", next_step_id: outer_path_a.id },
          { name: "Take outer path B", value: "outer_b", next_step_id: outer_path_b.id },
        ],
      )
      outer_choice.update!(branch_join_step: outer_join)
      inner_choice.set_answers!(
        answers: [
          { name: "Take inner path A", value: "inner_a", next_step_id: inner_path_a.id },
          { name: "Take inner path B", value: "inner_b", next_step_id: inner_path_b.id },
        ],
      )
      inner_choice.update!(branch_join_step: inner_join)

      outer_choice.add_text!(text: "Outer path A contains a second choice.", text_class: "govuk-body")
      inner_choice.add_text!(text: "Both inner paths rejoin before the outer paths rejoin.", text_class: "govuk-body")
      after_inner_join.add_text!(text: "The next step follows the outer branch to its join.", text_class: "govuk-body")

      puts "Built registration journey: #{registration_journey.slug}"
    end
  end
end
