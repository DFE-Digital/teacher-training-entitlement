FactoryBot.define do
  factory :outcome, aliases: [:participant_outcome] do
    transient do
      user { create(:user) }
      lead_provider { create(:lead_provider) }
      course { create(:course) }
    end

    passed
    completion_date { 1.week.ago }
    ecf_id { SecureRandom.uuid }
    declaration do
      association :declaration, :completed, :payable, lead_provider:, user:
    end

    trait :passed do
      state { "passed" }
    end

    trait :failed do
      state { "failed" }
    end

    trait :voided do
      state { "voided" }
    end
  end
end
