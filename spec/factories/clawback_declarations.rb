FactoryBot.define do
  factory :clawback_declaration do
    paid_declaration { create(:declaration, :paid) }
    application { paid_declaration.application }
    milestone { paid_declaration.milestone }
    cohort { paid_declaration.cohort }
    declaration_date { paid_declaration.declaration_date }
    declaration_type { paid_declaration.declaration_type }
    delivery_partner { paid_declaration.delivery_partner }
    secondary_delivery_partner { paid_declaration.secondary_delivery_partner }
    lead_provider { paid_declaration.lead_provider }
    statement { Statement.current_for(lead_provider:) || create(:statement, lead_provider:) }
  end
end
