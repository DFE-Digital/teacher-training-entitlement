FactoryBot.define do
  factory :registration_journey do
    sequence(:name) { |n| "Registration journey #{n}" }
    sequence(:slug) { |n| "registration-journey-#{n}" }
  end

  factory :registration_step do
    registration_journey
    sequence(:name) { |n| "Registration step #{n}" }
    sequence(:slug) { |n| "registration-step-#{n}" }
    type { "RegistrationSteps::Plain" }
    config { {} }

    initialize_with { type.constantize.new(**attributes) }
  end
end
