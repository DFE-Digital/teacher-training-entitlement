FactoryBot.define do
  factory :participant_outcome do
    transient do
      user { create(:user) }
      lead_provider { create(:lead_provider) }
      course { Course.find_by!(identifier: ParticipantOutcomes::Create::PERMITTED_COURSES.first) }
    end

    passed
    completion_date { 1.week.ago }
    ecf_id { SecureRandom.uuid }
    declaration { association :declaration, :completed, :payable, lead_provider:, course:, user: }

    trait :passed do
      state { "passed" }
    end

    trait :failed do
      state { "failed" }
    end

    trait :voided do
      state { "voided" }
    end

    trait :for_application do
      transient do
        application { create(:application, :accepted, user:, course:, lead_provider:) }
        declaration_type { Declaration::COMPLETED }
        declaration_state { :payable }
      end

      declaration do
        create(:declaration, application:, lead_provider:, declaration_type:, state: declaration_state)
      end
    end
  end
end
