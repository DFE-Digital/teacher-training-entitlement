FactoryBot.define do
  factory :course do
    sequence(:name) { |n| "TTE Course #{n}" }
    sequence(:identifier) { |n| "identifier-#{n}" }
    ecf_id { SecureRandom.uuid }
    course_group

    initialize_with do
      Course.find_by(identifier:) || new(**attributes)
    end

    trait :tte_early_years do
      sequence(:name) { |n| "TTE Early Years Course #{n}" }
      identifier { "tte-early-years" }
      course_group { create(:course_group, name: "reception") }
      short_code { "TTEEY" }
    end

    factory :"tte-early-years", traits: [:tte_early_years]
  end
end
