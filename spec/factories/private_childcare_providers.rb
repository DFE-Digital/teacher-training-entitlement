FactoryBot.define do
  sequence(:pcp_urn) { |n| (100_000 + n).to_s }

  factory :private_childcare_provider do
    transient do
      name { "private childcare provider" }
      provider_urn { generate(:pcp_urn) }
      institution { nil }
      address_1 { "5 Charlotte Road" }
      address_2 { nil }
      address_3 { nil }
      town { nil }
      county { nil }
      postcode { nil }
      postcode_without_spaces { nil }
      region { nil }
    end

    after(:build) do |provider, evaluator|
      provider.institution = evaluator.institution || build(:institution,
                                                            institutionable: provider,
                                                            name: evaluator.name,
                                                            address_1: evaluator.address_1,
                                                            address_2: evaluator.address_2,
                                                            address_3: evaluator.address_3,
                                                            town: evaluator.town,
                                                            county: evaluator.county,
                                                            postcode: evaluator.postcode,
                                                            postcode_without_spaces: evaluator.postcode_without_spaces,
                                                            region: evaluator.region,
                                                            institution_reference_number: evaluator.provider_urn)
    end

    after(:create) do |provider, _evaluator|
      provider.institution.save! if provider.institution&.new_record?
    end

    trait :disabled do
      disabled_at { 1.day.ago }
    end

    trait :on_early_years_register do
      early_years_individual_registers { %w[EYR] }
    end

    trait :on_all_registers do
      early_years_individual_registers { %w[CCR VCR EYR] }
    end

    trait :redacted do
      name { "REDACTED" }
      address_1 { "REDACTED" }
      address_2 { "REDACTED" }
      address_3 { "REDACTED" }
      town { "REDACTED" }
      postcode { "REDACTED" }
      postcode_without_spaces { "REDACTED" }
      region { "London" }
    end
  end
end
