FactoryBot.define do
  sequence(:la_ukprn) { |n| (10_000_000 + n).to_s }

  factory :local_authority do
    transient do
      name { "local authority" }
      ukprn { generate(:la_ukprn) }
      institution { nil }
      address_1 { nil }
      address_2 { nil }
      address_3 { nil }
      town { nil }
      county { nil }
      postcode { nil }
      postcode_without_spaces { nil }
    end

    after(:build) do |la, evaluator|
      la.institution = evaluator.institution || build(:institution,
                                                      institutionable: la,
                                                      name: evaluator.name,
                                                      address_1: evaluator.address_1,
                                                      address_2: evaluator.address_2,
                                                      address_3: evaluator.address_3,
                                                      town: evaluator.town,
                                                      county: evaluator.county,
                                                      postcode: evaluator.postcode,
                                                      postcode_without_spaces: evaluator.postcode_without_spaces,
                                                      institution_reference_number: evaluator.ukprn)
    end

    after(:create) do |la, _evaluator|
      la.institution.save! if la.institution&.new_record?
    end
  end
end
