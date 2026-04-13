FactoryBot.define do
  factory :application_event do
    application
    event { "StateChange::Application::ACCEPTED" }

    trait :accepted do
      event { "StateChange::Application::ACCEPTED" }
    end

    trait :started do
      event { "StateChange::Application::STARTED" }
    end

    trait :withdrawn do
      event { "StateChange::Application::WITHDRAWN" }
      metadata { { "reason" => "other" } }
    end

    trait :deferred do
      event { "StateChange::Application::DEFERRED" }
      metadata { { "reason" => "other" } }
    end
  end
end
