FactoryBot.define do
  factory :declaration do
    transient do
      user { create(:user) }
      course { nil }
      course_cohort { course ? create(:course_cohort, course:) : create(:course_cohort) }
      statement { nil }
      paid_statement { nil }
    end

    application { Application.has_been_accepted.find_by(user:, course_cohort:) || association(:application, :accepted, user:, course_cohort:) }
    lead_provider { application&.lead_provider || create(:lead_provider) }
    cohort { course_cohort.cohort }

    delivery_partner { create(:delivery_partner, lead_providers: { cohort => lead_provider }) }
    started
    declaration_date { application.schedule.training_starts_at + 1.day }
    submitted
    ecf_id { SecureRandom.uuid }

    after(:create) do |declaration, evaluator|
      if evaluator.statement && declaration.state != "submitted"
        create(:statement_item, declaration:, state: declaration.state, statement: evaluator.statement)
      end
    end

    trait :submitted_or_eligible do
      state do
        if application && application.eligible_for_funding && application.funded_place
          :eligible
        else
          :submitted
        end
      end
    end

    trait :submitted do
      state { :submitted }
    end
    trait :payable do
      state { :payable }
    end

    trait :paid do
      state { :paid }
    end

    trait :ineligible do
      state { :ineligible }
    end

    trait :voided do
      state { :voided }
    end

    trait :started do
      declaration_type { :started }
    end

    trait :completed do
      declaration_type { :completed }
    end

    trait :from_ecf do
      ecf_id { SecureRandom.uuid }
    end

    trait :billable_or_voidable do
      state { (Declaration::BILLABLE_STATES + Declaration::VOIDABLE_STATES).uniq.sample }
    end

    trait :with_delivery_partner do
      delivery_partner { create(:delivery_partner, lead_providers: { cohort => lead_provider }) }
    end

    trait :with_sometimes_nil_delivery_partner do
      delivery_partner do
        if cohort.start_year.between?(2021, 2023)
          [nil, create(:delivery_partner, lead_providers: { cohort => lead_provider })].sample
        else
          create(:delivery_partner, lead_providers: { cohort => lead_provider })
        end
      end
    end

    trait :with_secondary_delivery_partner do
      secondary_delivery_partner { create(:delivery_partner, lead_providers: { cohort => lead_provider }) }
    end
  end
end
