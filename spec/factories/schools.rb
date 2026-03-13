FactoryBot.define do
  sequence(:urn) { |n| sprintf("1TEST%05d", n % 100_000) }
  sequence(:ukprn) { |n| sprintf("TEST%08d", n % 100_000_000) }

  factory :school do
    transient do
      name { Faker::Educator.primary_school }
      urn { generate(:urn) }
      institution { nil }
      address_1 { nil }
      address_2 { nil }
      address_3 { nil }
      town { nil }
      county { nil }
      postcode { nil }
      postcode_without_spaces { nil }
      region { nil }
    end

    ukprn { generate(:ukprn) }
    establishment_status_code { "1" }
    establishment_type_code { "1" } # Community school (eligible)
    last_changed_date { Date.new(2010, 1, 1) }

    after(:build) do |school, evaluator|
      school.institution = evaluator.institution || build(:institution,
                                                          institutionable: school,
                                                          name: evaluator.name,
                                                          address_1: evaluator.address_1,
                                                          address_2: evaluator.address_2,
                                                          address_3: evaluator.address_3,
                                                          town: evaluator.town,
                                                          county: evaluator.county,
                                                          postcode: evaluator.postcode,
                                                          postcode_without_spaces: evaluator.postcode_without_spaces,
                                                          region: evaluator.region,
                                                          institution_reference_number: evaluator.urn)
    end

    after(:create) do |school, _evaluator|
      school.institution.save! if school.institution&.new_record?
    end

    trait :non_pp50 do
      urn do
        urn = nil

        loop do
          urn = generate(:urn)
          break unless PP50_SCHOOLS_URN_HASH[urn.to_s]
        end

        urn
      end

      ukprn do
        ukprn = nil

        loop do
          ukprn = generate(:ukprn)
          break unless PP50_FE_UKPRN_HASH[ukprn.to_s]
        end

        ukprn
      end
    end

    trait :funding_eligible_establishment_type_code do
      establishment_type_code { "1" }
      eyl_funding_eligible { true }
    end

    trait :local_authority_nursery_school do
      establishment_type_code { "15" }
    end

    trait :closed do
      establishment_status_code { 2 }
    end

    trait :with_address do
      address_1 { Faker::Address.building_number }
      address_2 { Faker::Address.street_address }
      address_3 { Faker::Address.community }
      town { "town" }
      county { "county" }
      postcode { Faker::Address.postcode }
    end

    trait :in_wales do
      urn { "40000" }
      establishment_type_code { "30" }
    end

    trait :ineligible_establishment_type do
      establishment_type_code { "11" } # Other independent school
    end
  end
end
