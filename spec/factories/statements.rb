FactoryBot.define do
  factory :statement do
    start_date { Date.current.beginning_of_month }
    frequency { Statement::FREQUENCIES.keys.first }
    deadline_date { start_date + Statement::FREQUENCIES.fetch(frequency) - 1.day }
    payment_date { deadline_date ? deadline_date + 3.days : Faker::Date.forward(days: 30) }
    lead_provider
    reconcile_amount { Faker::Number.decimal(l_digits: 3, r_digits: 2) }
    state { "open" }
    ecf_id { SecureRandom.uuid }
    output_fee { true }
    academic_year { Date.current.year }

    trait :next_output_fee do
      start_date { 1.month.from_now }
      output_fee { true }
    end

    trait :paid do
      state { "paid" }
      start_date { 2.months.ago }
      marked_as_paid_at { 1.week.ago }
    end

    trait(:open) { state { "open" } }

    trait :payable do
      state { "payable" }
      start_date { 1.month.ago }
    end

    trait :with_existing_lead_provider do
      lead_provider { LeadProvider.first }
    end

    trait :with_milestones do
      after :create do |statement|
        create(:declaration, :started, statement: statement, lead_provider: statement.lead_provider)
      end
    end
  end
end
