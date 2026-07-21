FactoryBot.define do
  factory :clawback_declaration do
    milestone
    cohort
    declaration_date { milestone.acceptance_window_start_date }
    declaration_type { milestone.declaration_type }
    application { create(:application, :with_declaration) }
    paid_declaration { application.declarations.first }
    delivery_partner { create(:delivery_partner, lead_providers: { cohort => lead_provider }) }
    lead_provider { application&.lead_provider || create(:lead_provider) }
  end
end
