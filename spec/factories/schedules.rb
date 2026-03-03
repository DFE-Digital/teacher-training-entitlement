FactoryBot.define do
  factory :schedule do
    transient do
      change_applies_dates { true }
    end

    course_group { "reception" }
    cohort { create(:cohort, :current) }

    sequence(:name) { |n| "Schedule #{n}" }
    sequence(:identifier) { |n| "schedule-#{n}" }

    applies_from { Date.new(cohort.start_year, 10, 1) }
    applies_to { Date.new(cohort.start_year, 11, 1) }

    allowed_declaration_types { %w[started retained-1 retained-2 completed] }

    policy_descriptor { 1 }
    acceptance_window_start { Date.new(cohort.start_year, 1, 1) }
    acceptance_window_end { Date.new(cohort.start_year, 12, 31) }

    initialize_with do
      Schedule.find_by(cohort:, identifier:) || new(**attributes)
    end

    trait :tte_reception_autumn do
      name { "TTE Reception autumn" }
      identifier { "tte-reception-autumn" }
      course_group { "reception" }

      applies_from { Date.new(cohort.start_year, 10, 1) }
      applies_to { Date.new(cohort.start_year, 12, 31) }
    end

    trait :tte_reception_spring do
      name { "TTE Reception spring" }
      identifier { "tte-reception-spring" }
      course_group { "reception" }

      applies_from { Date.new(cohort.start_year + 1, 1, 1) }
      applies_to { Date.new(cohort.start_year + 1, 3, 31) }
    end

    trait :tte_send_autumn do
      name { "TTE Send autumn" }
      identifier { "tte-send-autumn" }
      course_group { "send" }

      applies_from { Date.new(cohort.start_year, 10, 1) }
      applies_to { Date.new(cohort.start_year, 12, 31) }
    end

    trait :tte_send_spring do
      name { "TTE Send spring" }
      identifier { "tte-send-spring" }
      course_group { "send" }

      applies_from { Date.new(cohort.start_year + 1, 1, 1) }
      applies_to { Date.new(cohort.start_year + 1, 3, 31) }
    end

    # Setting the schedule dates to 1 week ago is to ensure that
    # without time travel declaration factories are valid. Declaration model
    # validations require the `declaration_date` not to be in the future, and
    # to be after the application schedule `applies_from` date. We can disable
    # this callback via the transient `change_applies_dates` attribute by
    # setting it to false
    before(:create) do |schedule, evaluator|
      if schedule.applies_from.future? && evaluator.change_applies_dates
        schedule.applies_from = Date.current - 1.month
        schedule.applies_to = Date.current + 1.month
      end
    end
  end
end
