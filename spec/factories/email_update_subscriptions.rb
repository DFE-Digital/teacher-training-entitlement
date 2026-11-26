FactoryBot.define do
  factory :email_update_subscription do
    sequence(:email) { |n| "subscriber#{n}@example.com" }
    full_name { "Jo Bloggs" }
    status { EmailUpdateSubscription::NPD_REGISTRATION_OPEN }
  end
end
