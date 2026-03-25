FactoryBot.define do
  factory :schedule do
    transient do
      change_training_dates { true }
    end

    course_group { "reception" }
    cohort { create(:cohort, :current) }

    sequence(:name) { |n| "Schedule #{n}" }
    sequence(:identifier) { |n| "schedule-#{n}" }

    training_starts_at { Date.new(cohort.start_year, 10, 1) }
    training_ends_at { Date.new(cohort.start_year, 11, 1) }

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

      training_starts_at { Date.new(cohort.start_year, 10, 1) }
      training_ends_at { Date.new(cohort.start_year, 12, 31) }
    end

    trait :tte_reception_spring do
      name { "TTE Reception spring" }
      identifier { "tte-reception-spring" }
      course_group { "reception" }

      training_starts_at { Date.new(cohort.start_year + 1, 1, 1) }
      training_ends_at { Date.new(cohort.start_year + 1, 3, 31) }
    end

    trait :tte_send_autumn do
      name { "TTE Send autumn" }
      identifier { "tte-send-autumn" }
      course_group { "send" }

      training_starts_at { Date.new(cohort.start_year, 10, 1) }
      training_ends_at { Date.new(cohort.start_year, 12, 31) }
    end

    trait :tte_send_spring do
      name { "TTE Send spring" }
      identifier { "tte-send-spring" }
      course_group { "send" }

      training_starts_at { Date.new(cohort.start_year + 1, 1, 1) }
      training_ends_at { Date.new(cohort.start_year + 1, 3, 31) }
    end

    # Setting the schedule dates to 1 week ago is to ensure that
    # without time travel declaration factories are valid. Declaration model
    # validations require the `declaration_date` not to be in the future, and
    # to be after the application schedule `training_starts_at` date. We can disable
    # this callback via the transient `change_training_dates` attribute by
    # setting it to false
    before(:create) do |schedule, evaluator|
      if schedule.training_starts_at.future? && evaluator.change_training_dates
        schedule.training_starts_at = Date.current - 1.month
        schedule.training_ends_at = Date.current + 1.month
      end
    end
  end
end
