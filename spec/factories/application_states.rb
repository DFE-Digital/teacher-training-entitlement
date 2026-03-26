# frozen_string_literal: true

FactoryBot.define do
  factory :application_state do
    application
    lead_provider { LeadProvider.first }
    status { Application::ACCEPTED }

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
