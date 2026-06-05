FactoryBot.define do
  factory :user do
    sequence(:full_name) { |n| "John Doe #{n}" }
    sequence(:email) { Faker::Internet.email(name: full_name) }
    sequence(:trn) { |n| sprintf("%07i", n % 10_000_000) }
    date_of_birth { 30.years.ago }
    ecf_id { SecureRandom.uuid }
    significantly_updated_at { Time.zone.now }

    trait :without_significantly_updated_at do
      significantly_updated_at { nil }
    end

    trait :with_one_login_id do
      one_login_id { SecureRandom.uuid }
      provider { Omniauth::Strategies::TeacherAuth::NAME.to_s }
    end

    trait :with_random_name do
      full_name { Faker::Name.name }
    end

    trait :with_application do
      transient do
        lead_provider { LeadProvider.first }
      end

      after(:create) do |user, evaluator|
        create(:application, :accepted, user:, lead_provider: evaluator.lead_provider)
      end
    end

    trait :archived do
      archived_email { Faker::Internet.email(name: full_name) }
      archived_at { Time.zone.now }
      email { "archived-#{archived_email}" }
    end
  end
end
