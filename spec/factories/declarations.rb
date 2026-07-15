FactoryBot.define do
  factory :declaration do
    transient do
      user { create(:user) }
      course { nil }
      statement { nil }
      paid_statement { nil }
      change_training_dates { true }
    end

    application do
      application_course = course || create(:course)

      association(:application, :accepted, user:, course: application_course, cohort: create(:cohort, :previous, course: application_course))
    end
    lead_provider { application&.lead_provider || create(:lead_provider) }
    cohort { application.cohort }

    delivery_partner { create(:delivery_partner, lead_providers: { cohort => lead_provider }) }
    started
    declaration_date { cohort&.training_starts_at || Time.zone.today }
    submitted
    ecf_id { SecureRandom.uuid }

    after(:create) do |declaration, evaluator|
      if evaluator.statement && declaration.state != "submitted"
        if declaration.state.in? %w[awaiting_clawback clawed_back]
          raise ArgumentError, "Declaration state #{declaration.state} also requires paid_statement" if evaluator.paid_statement.nil?

          create(:statement_item, declaration:, state: "paid", statement: evaluator.paid_statement)
        end

        create(:statement_item, declaration:, state: declaration.state, statement: evaluator.statement)
      end
    end

    before(:create) do |declaration, evaluator|
      next unless evaluator.change_training_dates

      cohort = declaration.cohort
      next unless cohort
      next unless cohort.training_starts_at.future?

      cohort.update_columns(
        training_starts_at: 1.month.ago.to_date,
        training_ends_at: 1.month.from_now.to_date,
      )
      declaration.declaration_date = cohort.reload.training_starts_at
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

    trait :awaiting_clawback do
      state { :awaiting_clawback }
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
