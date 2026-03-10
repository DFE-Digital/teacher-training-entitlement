FactoryBot.define do
  factory :local_authority do
    transient do
      name { "local authority" }
      address_1 { nil }
      address_2 { nil }
      address_3 { nil }
      town { nil }
      county { nil }
      postcode { nil }
      postcode_without_spaces { nil }
    end

    sequence(:ukprn) { |n| (10_000_000 + n).to_s }

    after(:build) do |la, evaluator|
      la.institution ||= build(:institution, :for_local_authority,
                               institutionable: la,
                               name: evaluator.name,
                               address_1: evaluator.address_1,
                               address_2: evaluator.address_2,
                               address_3: evaluator.address_3,
                               town: evaluator.town,
                               county: evaluator.county,
                               postcode: evaluator.postcode,
                               postcode_without_spaces: evaluator.postcode_without_spaces)
    end

    after(:create) do |la, _evaluator|
      la.institution.save! if la.institution&.new_record?
    end
  end
end
