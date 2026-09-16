FactoryBot.define do
  factory :course_cohort do
    association :course, factory: :"tte-early-years"
    cohort
    academic_year { cohort.registration_starts_at.year - (cohort.registration_starts_at.month < 9 ? 1 : 0) }
    term_identifier { :autumn }
    training_starts_at { 3.months.ago.to_date }
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
