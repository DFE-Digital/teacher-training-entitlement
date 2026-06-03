FactoryBot.define do
  factory :course_cohort do
    association :course, factory: :"tte-early-years"
    cohort

    schedule do
      CourseCohort.find_by(course:, cohort:)&.schedule || create(:schedule, cohort:)
    end

    initialize_with do
      CourseCohort.find_or_initialize_by(course:, cohort:)
    end

    transient do
      lead_provider { nil }
    end

    after(:create) do |course_cohort, evaluator|
      if evaluator.lead_provider || course_cohort.course_cohort_providers.empty?
        lead_provider = evaluator.lead_provider || LeadProvider.first || create(:lead_provider)
        course_cohort.course_cohort_providers << create(:course_cohort_provider, lead_provider:, course_cohort:)
      end
    end
  end
end
