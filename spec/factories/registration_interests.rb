FactoryBot.define do
  factory :registration_interest do
    email { "johndoe@example.com" }

    trait :notified do
      notified { true }
    end
  end
end
