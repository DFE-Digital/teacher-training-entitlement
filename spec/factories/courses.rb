FactoryBot.define do
  factory :course do
    sequence(:name) { |n| "TTE Course #{n}" }
    sequence(:identifier) { |n| "identifier-#{n}" }
    ecf_id { SecureRandom.uuid }
    course_group { "reception" }

    initialize_with do
      Course.find_by(identifier:) || new(**attributes)
    end

    trait :tte_early_years do
      sequence(:name) { |n| "TTE Early Years Course #{n}" }
      identifier { "tte-early-years" }
      course_group { "reception" }
      short_code { "TTEEY" }
    end

    factory :"tte-early-years", traits: [:tte_early_years]

    transient do
      lead_provider { nil }
    end

    after(:create) do |course, evaluator|
      if course.course_cohorts.empty?
        cohort = begin
          Cohort.current
        rescue StandardError
          create(:cohort, :current)
        end
        schedule = Schedule.where(cohort:).first || create(:schedule, cohort:)
        course.course_cohorts << create(:course_cohort, course:, cohort:, schedule:, lead_provider: evaluator.lead_provider)
      end
    end
  end
end
