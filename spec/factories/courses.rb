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
      identifier { Course::TTE_EARLY_YEARS }
      course_group { "reception" }
      short_code { "NPDEIRT" }
    end

    trait :npd_send_eipl do
      sequence(:name) { |n| "Embedding inclusive practice for leaders #{n}" }
      identifier { Course::SEND_INCLUSIVE_LEADERS }
      course_group { "send" }
      short_code { "NPDEIPL" }
    end

    trait :npd_send_eip do
      sequence(:name) { |n| "Embedding inclusive practice #{n}" }
      identifier { Course::SEND_INCLUSIVE_TEACHERS }
      course_group { "send" }
      short_code { "NPDEIP" }
    end

    factory :"npd-excellence-in-reception-teaching", traits: [:npd_eirt]
    factory :"npd-eirt", traits: [:npd_eirt]
    factory :"tte-early-years", traits: [:npd_eirt]
    factory :"tte-reception", traits: [:npd_eirt]
    factory :"npd-send-eip", traits: [:npd_send_eip]
    factory :"npd-send-eipl", traits: [:npd_send_eipl]

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
