FactoryBot.define do
  factory :state_change do
    application
    event { Application::ACCEPTED }

    trait :accepted do
      event { Application::ACCEPTED }
    end

    trait :started do
      event { Application::STARTED }
    end

    trait :withdrawn do
      event { Application::WITHDRAWN }
      metadata { { "reason" => "other" } }
    end

    trait :deferred do
      event { Application::DEFERRED }
      metadata { { "reason" => "other" } }
    end

    trait :rejected do
      event { Application::REJECTED }
      metadata { { "reason" => "rejected-by-provider" } }
    end
  end

  factory :notification do
    application
    event { "application_submitted" }
  end
end
