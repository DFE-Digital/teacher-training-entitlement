# frozen_string_literal: true

FactoryBot.define do
  factory :application_state do
    application
    accepted
    lead_provider { LeadProvider.first }

    trait :started do
      status { Application::STARTED }
    end

    trait :accepted do
      status { Application::ACCEPTED }
    end

    trait :withdrawn do
      status { Application::WITHDRAWN }
      reason { "other" }
    end

    trait :deferred do
      status { Application::DEFERRED }
      reason { "other" }
    end
  end
end
