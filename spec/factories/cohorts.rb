FactoryBot.define do
  factory :cohort do
    sequence(:start_year, 0) { |n| 2021 + n % 9 }
    registration_starts_at { Date.new(start_year, 4, 3) }
    funding_cap { true }

    description do
      registration_starts_at.strftime("%B %Y")
    end

    identifier do
      registration_starts_at.strftime("%Y-%B")
    end

    initialize_with do
      Cohort.find_or_create_by(registration_starts_at:)
    end

    trait :current do
      start_year { Date.current.month < 9 ? Date.current.year.pred : Date.current.year }
    end

    trait :next do
      start_year { Date.current.month < 9 ? Date.current.year : Date.current.year.succ }
    end

    trait :previous do
      start_year { Date.current.month < 9 ? Date.current.year : (Date.current.year - 1) }
    end

    trait :unique do
      sequence(:registration_starts_at, 0) do |n|
        year = 2021 + (n / 12) % 9
        month = (n % 12) + 1

        Date.new(year, month, 3)
      end
      start_year { registration_starts_at.year }
      description { "#{registration_starts_at.year} #{registration_starts_at.strftime('%B')}" }
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
