FactoryBot.define do
  factory :institution do
    sequence(:name) { |n| "Institution #{n}" }

    # Default to creating a school as the institutionable
    for_school

    trait :for_school do
      institutionable { association :school, institution: instance }
    end

    trait :for_private_childcare_provider do
      institutionable { association :private_childcare_provider, institution: instance }
    end

    trait :for_local_authority do
      institutionable { association :local_authority, institution: instance }
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
