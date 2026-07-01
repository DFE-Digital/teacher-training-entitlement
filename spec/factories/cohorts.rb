FactoryBot.define do
  factory :cohort do
    registration_starts_at { 1.week.ago.to_date.beginning_of_month }
    registration_ends_at { registration_starts_at.advance(months: 2) }
    funding_cap { true }
    description { registration_starts_at.strftime("%B %Y") }
    identifier { registration_starts_at.strftime("%Y-%B") }

    initialize_with do
      Cohort.find_or_initialize_by(identifier:) do |cohort|
        cohort.assign_attributes(attributes)
      end
    end

    trait :current do
      registration_starts_at { 1.week.ago.to_date.beginning_of_month }
    end

    trait :next do
      registration_starts_at { 1.week.ago.to_date.beginning_of_month.next_year }
    end

    trait :previous do
      registration_starts_at { 1.week.ago.to_date.beginning_of_month.prev_year }
    end

    trait :with_funding_cap do
      funding_cap { true }
    end

    trait :without_funding_cap do
      funding_cap { false }
    end

    trait :has_targeted_delivery_funding do
      registration_starts_at { Date.new(2022, 4, 1) }
    end
  end
end
