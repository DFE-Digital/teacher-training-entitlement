FactoryBot.define do
  factory :api_token do
    transient do
      raw_token { "token" }
    end

    lead_provider { create(:lead_provider) }
    hashed_token { Devise.token_generator.digest(APIToken, :hashed_token, raw_token) }

    trait :webhook do
      raw_token { "webhook_token" }
      lead_provider { nil }
      scope { APIToken.scopes[:webhook] }
    end
  end
end
