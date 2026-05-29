# frozen_string_literal: true

FactoryBot.define do
  factory :application_lead_provider do
    application
    lead_provider

    trait :current do
      current { true }
      assigned_at { Time.zone.now }
    end

    trait :unassigned do
      current { false }
      assigned_at { 1.month.ago }
      unassigned_at { Time.zone.now }
    end
  end
end
