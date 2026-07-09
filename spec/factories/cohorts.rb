FactoryBot.define do
  factory :cohort do
    sequence(:start_year, 0) { |n| 2021 + n % 9 }
    registration_starts_at { Date.new(start_year, [Date.current.month - 1, 1].max, 3) }
    registration_ends_at { registration_starts_at.advance(months: 2) }
    training_starts_at { 1.day.ago.to_date }
    training_ends_at { 1.month.from_now.to_date }
    funding_cap { true }
    description { registration_starts_at.strftime("%B %Y") }
    identifier { registration_starts_at.strftime("%Y-%B") }
    course { Course.reception || create(:course, :npd_eirt) }

    initialize_with do
      Cohort.find_or_create_by(registration_starts_at:)
    end

    transient do
      lead_provider { nil }
    end

    after(:create) do |cohort, evaluator|
      if evaluator.lead_provider || cohort.cohort_providers.empty?
        lead_provider = evaluator.lead_provider || LeadProvider.first || create(:lead_provider)
        cohort.cohort_providers.find_or_create_by!(lead_provider:)
      end
    end

    trait :current do
      start_year { Date.current.year }
    end

    trait :next do
      start_year { Date.current.year.succ }
    end

    trait :previous do
      start_year { Date.current.year.pred }
    end

    trait :future_training do
      training_starts_at { 1.month.from_now.to_date }
      training_ends_at { 6.months.from_now.to_date }
    end

    trait :unique do
      sequence(:registration_starts_at, 0) do |n|
        year = 2021 + (n / 12) % 9
        month = (n % 12) + 1

        Date.new(year, month, 3)
      end
      start_year { registration_starts_at.year }
    end

    trait :with_funding_cap do
      funding_cap { true }
    end

    trait :without_funding_cap do
      funding_cap { false }
    end

    trait :has_targeted_delivery_funding do
      start_year { 2022 }
    end
  end
end
