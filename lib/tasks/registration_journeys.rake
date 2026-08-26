namespace :registration_journeys do
  desc "Recreate the registration templates used by the DB-driven registration journey spike"
  task recreate_registration_templates: :environment do
    templates = [
      {
        name: "Simple NPD style registration",
        description: "A simple NPD style funding eligibility template generator which captures teacher catchment, work setting and school",
        template_generating_service_class: "Registrations::StepTemplates::Courses::NpdStyleService",
      },
      {
        name: "Demo food journey",
        description: "Demo of creating a branched journey",
        template_generating_service_class: "Registrations::StepTemplates::FoodJourneyService",
      },
      {
        name: "NPD Recreation",
        description: "A recreation of the current NPD course registration",
        template_generating_service_class: "Registrations::StepTemplates::Courses::NpdService",
      },
      {
        name: "Simple work setting based funding eligibility",
        description: "Apply steps & funding eligibility service to a registration journey which ask the classic questions for funding (NPD style)",
        template_generating_service_class: "Registrations::StepTemplates::FundingEligibility::WorkSettingFundingTemplateService",
      },
      {
        name: "Simple food based funding eligibility",
        description: "Apply a step & funding eligibility service to a registration journey",
        template_generating_service_class: "Registrations::StepTemplates::FundingEligibility::FoodFundingTemplateService",
      },
      {
        name: "NPQ inspired journey",
        description: "30 odd steps from the NPQ journey",
        template_generating_service_class: "Registrations::StepTemplates::NpqInspiredJourneyService",
      },
    ]

    templates.each do |attributes|
      registration_template = RegistrationTemplate.find_or_initialize_by(
        template_generating_service_class: attributes.fetch(:template_generating_service_class),
      )
      registration_template.update!(attributes)

      puts "Saved #{registration_template.name}: /admin/registration-templates/#{registration_template.id}"
    end
  end

  desc "Course selector journey"
  task create_course_selector: :environment do
    journey_slug = "course-selector"

    journey = RegistrationJourney.transaction do
      existing_journey = RegistrationJourney.find_by(slug: journey_slug)
      if existing_journey
        puts "Removing existing #{existing_journey.name}: /admin/registration-journeys/#{existing_journey.id}"
        existing_journey.destroy!
      end

      journey = RegistrationJourney.create!(
        name: "Course selector",
        slug: journey_slug,
      )

      create_step = lambda do |name:, slug:, type:, order:, answers: [], previous_step: nil|
        type_as_param = type.underscore.parameterize.underscore
        config = if answers.any?
                   {
                     type_as_param => {
                       "answers" => answers.map do |answer|
                         answer = answer.with_indifferent_access
                         {
                           "name" => answer[:name],
                           "value" => answer[:value].presence || answer[:name].to_s.underscore.parameterize.underscore,
                           "redirect" => { "path" => answer[:redirect_path].presence }.compact.presence,
                         }.compact
                       end,
                     },
                   }
                 else
                   {}
                 end
        config["previous_step_id"] = previous_step.id if previous_step

        journey.registration_steps.create!(name:, slug:, type:, order:, config:)
      end

      create_step.call(
        name: "Which course would you like to do?",
        slug: "courses",
        type: "Radio buttons",
        order: 1,
        answers: [
          { name: "Reception course", redirect_path: "/registrations/reception" },
          { name: "SEND course", redirect_path: "/registrations/send" },
        ],
      )
    end

    puts "Created #{journey.name}: /admin/registration-journeys/#{journey.id}"
  end

  desc "Create an NPQ-inspired DB-driven demo registration journey"
  task create_npq_inspired_journey: :environment do
    journey_slug = "npq-inspired-demo"

    journey = RegistrationJourney.transaction do
      existing_journey = RegistrationJourney.find_by(slug: journey_slug)
      if existing_journey
        puts "Removing existing #{existing_journey.name}: /admin/registration-journeys/#{existing_journey.id}"
        existing_journey.destroy!
      end

      journey = RegistrationJourney.create!(
        name: "NPQ-inspired demo journey",
        slug: journey_slug,
      )

      Registrations::StepTemplates::NpqInspiredJourneyService
        .new(registration_journey: journey, registration_template: nil)
        .call

      journey
    end

    puts "Created #{journey.name}: /admin/registration-journeys/#{journey.id}"
  end

  desc "Recreate the Nested test registration journey dumped from journey ID 44"
  task create_nested_test_journey: :environment do
    journey_slug = "nested-test"
    step_definitions = [
      {
        source_id: 181,
        name: "first one",
        slug: "first-one",
        type: "Checkboxes",
        order: 1,
        config: {
          "checkboxes" => {
            "answers" => [
              { "name" => "Thing one" },
              { "name" => "Thing two" },
              { "name" => "Thing three" },
            ],
          },
        },
      },
      {
        source_id: 182,
        name: "Branch 1 - What cuisine?",
        slug: "branch-1---what-cuisine",
        type: "Radio buttons",
        order: 2,
        config: {
          "radio_buttons" => {
            "answers" => [
              { "name" => "Spicy" },
              { "name" => "Fresh" },
            ],
          },
        },
      },
      {
        source_id: 183,
        name: "What spicy continent?",
        slug: "what-spicy-continent",
        type: "Radio buttons",
        order: 3,
        config: {
          "radio_buttons" => {
            "answers" => [
              { "name" => "India" },
              { "name" => "Sri Lanka" },
              { "name" => "Pakistan" },
            ],
          },
        },
      },
      {
        source_id: 185,
        name: "What Sri Lanka curry?",
        slug: "what-sri-lanka-curry",
        type: "Radio buttons",
        order: 4,
        config: {
          "radio_buttons" => {
            "answers" => [
              { "name" => " Sour Fish Curry" },
              { "name" => "Jackfruit Curry (Polos)," },
            ],
          },
          "previous_step_id" => 183,
        },
      },
      {
        source_id: 184,
        name: "What Indian curry?",
        slug: "what-indian-curry",
        type: "Radio buttons",
        order: 5,
        config: {
          "radio_buttons" => {
            "answers" => [
              { "name" => "Goan Fish" },
              { "name" => "Rogan Josh" },
              { "name" => "Korma" },
            ],
          },
          "previous_step_id" => 183,
        },
      },
    ]

    journey = RegistrationJourney.transaction do
      existing_journey = RegistrationJourney.find_by(slug: journey_slug)
      if existing_journey
        puts "Removing existing #{existing_journey.name}: /admin/registration-journeys/#{existing_journey.id}"
        existing_journey.destroy!
      end

      journey = RegistrationJourney.create!(
        name: "Nested test",
        slug: journey_slug,
      )

      created_steps = step_definitions.each_with_object({}) do |definition, steps_by_source_id|
        steps_by_source_id[definition[:source_id]] = journey.registration_steps.create!(
          name: definition[:name],
          slug: definition[:slug],
          type: definition[:type],
          order: definition[:order],
          config: definition[:config],
        )
      end

      reference_keys = %w[previous_step_id next_step_id branch_join_step_id].freeze
      remap_references = lambda do |value, key = nil|
        case value
        when Hash
          value.to_h do |child_key, child_value|
            [child_key, remap_references.call(child_value, child_key)]
          end
        when Array
          value.map { |child_value| remap_references.call(child_value) }
        else
          if key.in?(reference_keys) && value.present?
            created_steps.fetch(value.to_i).id
          else
            value
          end
        end
      end

      step_definitions.each do |definition|
        created_steps.fetch(definition[:source_id]).update!(
          config: remap_references.call(definition[:config]),
        )
      end

      journey
    end

    puts "Created #{journey.name}: /admin/registration-journeys/#{journey.id}"
  end

  desc "Create a minimal journey demonstrating a nested branch and two explicit joins"
  task create_minimal_nested_demo_journey: :environment do
    journey_slug = "minimal-nested-demo"

    journey = RegistrationJourney.transaction do
      existing_journey = RegistrationJourney.find_by(slug: journey_slug)
      if existing_journey
        puts "Removing existing #{existing_journey.name}: /admin/registration-journeys/#{existing_journey.id}"
        existing_journey.destroy!
      end

      journey = RegistrationJourney.create!(
        name: "Minimal nested branch demo",
        slug: journey_slug,
      )

      create_step = lambda do |name:, slug:, type:, order:, previous_step: nil, answers: []|
        type_as_param = type.underscore.parameterize.underscore
        config = {}
        config["previous_step_id"] = previous_step.id if previous_step
        if answers.any?
          config[type_as_param] = {
            "answers" => answers.map { |answer| { "name" => answer } },
          }
        end

        journey.registration_steps.create!(name:, slug:, type:, order:, config:)
      end

      drink = create_step.call(
        name: "Choose a drink",
        slug: "choose-a-drink",
        type: "Radio buttons",
        order: 1,
      )
      milk = create_step.call(
        name: "Would you like milk in your coffee?",
        slug: "coffee-milk",
        type: "Radio buttons",
        order: 2,
        previous_step: drink,
      )
      milk_type = create_step.call(
        name: "Which kind of milk?",
        slug: "milk-type",
        type: "Radio buttons",
        order: 3,
        previous_step: milk,
        answers: %w[Dairy Oat],
      )
      black_coffee_style = create_step.call(
        name: "How would you like your coffee?",
        slug: "black-coffee-style",
        type: "Radio buttons",
        order: 4,
        previous_step: milk,
        answers: ["Black", "With sugar"],
      )
      coffee_size = create_step.call(
        name: "What size coffee?",
        slug: "coffee-size",
        type: "Radio buttons",
        order: 5,
        previous_step: milk,
        answers: %w[Small Large],
      )
      tea_type = create_step.call(
        name: "Which kind of tea?",
        slug: "tea-type",
        type: "Radio buttons",
        order: 6,
        previous_step: drink,
        answers: ["Breakfast tea", "Green tea"],
      )
      check_answers = create_step.call(
        name: "Check your answers",
        slug: "check-answers",
        type: "Check answers",
        order: 7,
      )

      milk.set_answers!(
        answers: [
          { "name" => "Yes", "next_step_id" => milk_type.id },
          { "name" => "No", "next_step_id" => black_coffee_style.id },
        ],
      )
      milk.update!(branch_join_step_id: coffee_size.id)

      drink.set_answers!(
        answers: [
          { "name" => "Coffee", "next_step_id" => milk.id },
          { "name" => "Tea", "next_step_id" => tea_type.id },
        ],
      )
      drink.update!(branch_join_step_id: check_answers.id)

      journey
    end

    puts "Created #{journey.name}: /admin/registration-journeys/#{journey.id}"
  end

  desc "Create a complicated food-themed registration journey"
  task create_complicated_food_journey: :environment do
    journey_slug = "complicated-food-journey"

    existing_journey = RegistrationJourney.find_by_slug(journey_slug)

    if existing_journey
      puts "Removing existing #{existing_journey.name}: /admin/registration-journeys/#{existing_journey.id}"
      existing_journey.destroy!
    end

    journey = RegistrationJourney.create!(
      name: "Complicated food journey",
      slug: journey_slug,
    )

    Registrations::StepTemplates::FoodJourneyService
      .new(registration_journey: journey, registration_template: nil)
      .call

    puts "Created #{journey.name}: /admin/registration-journeys/#{journey.id}"
  end
end
