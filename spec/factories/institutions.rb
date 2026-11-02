FactoryBot.define do
  factory :institution do
    sequence(:name) { |n| "Institution #{n}" }
    sequence(:institution_reference_number) { |n| sprintf("IRN%08d", n) }
    alpha3_country_code { Institution::UK_COUNTRY_CODE }
    subdivision_code { Institution::ENGLAND_SUBDIVISION_CODE }

    after(:build) do |institution|
      institution.institutionable ||= build(:school, institution: institution)
    end

    trait :not_in_england do
      alpha3_country_code { Institution::UK_COUNTRY_CODE }
      subdivision_code { Institution::WALES_SUBDIVISION_CODE }
    end

    trait :for_school do
      after(:build) do |institution|
        institution.institutionable ||= build(:school, institution: institution)
      end
    end

    trait :ineligible_school do
      after(:build) do |institution|
        institution.institutionable ||= build(:school, :ineligible, institution: institution)
      end
    end

    trait :for_private_childcare_provider do
      after(:build) do |institution|
        institution.institutionable ||= build(:private_childcare_provider, institution: institution)
      end
    end

    trait :for_local_authority do
      after(:build) do |institution|
        institution.institutionable ||= build(:local_authority, institution: institution)
      end
    end

    trait :with_address do
      address_1 { Faker::Address.building_number }
      address_2 { Faker::Address.street_address }
      address_3 { Faker::Address.community }
      town { "town" }
      county { "county" }
      postcode { Faker::Address.postcode }
    end
  end
end
