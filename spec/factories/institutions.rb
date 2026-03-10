FactoryBot.define do
  factory :institution do
    sequence(:name) { |n| "Institution #{n}" }

    trait :for_school do
      institutionable_type { "School" }
    end

    trait :for_private_childcare_provider do
      institutionable_type { "PrivateChildcareProvider" }
    end

    trait :for_local_authority do
      institutionable_type { "LocalAuthority" }
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
