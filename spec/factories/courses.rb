FactoryBot.define do
  factory :course do
    sequence(:name) { |n| "NPD Course #{n}" }
    sequence(:identifier) { |n| "identifier-#{n}" }
    ecf_id { SecureRandom.uuid }
    course_group { "reception" }

    initialize_with do
      Course.find_by(identifier:) || new(**attributes)
    end

    trait :npd_eirt do
      sequence(:name) { |n| "NPD excellence in reception teaching #{n}" }
      # identifier { "npd-excellence-in-reception-teaching" }
      identifier { "tte-early-years" }
      course_group { "reception" }
      short_code { "NPDEIRT" }
    end

    factory :"npd-excellence-in-reception-teaching", traits: [:npd_eirt]
    factory :"npd-eirt", traits: [:npd_eirt]
    factory :"tte-early-years", traits: [:npd_eirt]

    transient do
      lead_provider { nil }
      cohort { nil }
    end

    after(:create) do |course, evaluator|
      if course.milestones.empty?
        course.milestones << create(:milestone, :started, course: course, payment_percentage: 0.6, acceptance_window_start_offset: 0, acceptance_window_end_offset: 1)
        course.milestones << create(:milestone, :completed, course: course, payment_percentage: 0.4, acceptance_window_start_offset: 0, acceptance_window_end_offset: 1)
      end
      cohort = evaluator.cohort || create(:cohort, :current)
      course.course_cohorts << create(:course_cohort, course:, cohort:, lead_provider: evaluator.lead_provider)
    end
  end
end
