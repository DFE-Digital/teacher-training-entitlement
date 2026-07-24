FactoryBot.define do
  sequence(:participant_outcome_cohort_registration_starts_at) do |n|
    Date.new(2021, 1, 1).advance(months: n)
  end

  factory :participant_outcome do
    transient do
      user { create(:user) }
      lead_provider { create(:lead_provider) }
      course { Course.find_by!(identifier: ParticipantOutcomes::Create::PERMITTED_COURSES.first) }
      cohort_registration_starts_at { generate(:participant_outcome_cohort_registration_starts_at) }
    end

    passed
    completion_date { 1.week.ago }
    ecf_id { SecureRandom.uuid }
    declaration do
      course_cohort = create(
        :course_cohort,
        course:,
        cohort: create(:cohort, registration_starts_at: cohort_registration_starts_at),
      )

      association :declaration, :completed, :payable, lead_provider:, course:, course_cohort:, user:
    end

    trait :passed do
      state { "passed" }
    end

    trait :failed do
      state { "failed" }
    end

    trait :voided do
      state { "voided" }
    end
  end
end
