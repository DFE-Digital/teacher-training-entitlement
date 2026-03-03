FactoryBot.define do
  factory :course_cohort do
    course
    cohort

    transient do
      lead_provider { nil }
    end

    after(:create) do |course_cohort, evaluator|
      if course_cohort.course_cohort_providers.empty?
        lead_provider = evaluator.lead_provider || LeadProvider.first || create(:lead_provider)
        course_cohort.course_cohort_providers << create(:course_cohort_provider, lead_provider:, course_cohort:)
      end
    end
  end
end
