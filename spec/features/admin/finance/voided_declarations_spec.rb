# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Voided declarations", type: :feature do
  include Helpers::AdminLogin

  let(:cohort) { create(:cohort, training_starts_at: 1.month.ago, training_ends_at: 1.month.from_now) }
  let(:other_cohort) { create(:cohort, :unique, training_starts_at: 1.month.ago, training_ends_at: 1.month.from_now) }
  let(:statement) { create(:statement, cohort:) }
  let(:other_statement) { create(:statement, cohort: other_cohort) }

  let!(:eligible_declaration) { create(:declaration, :eligible, statement:, cohort: statement.cohort, lead_provider: statement.lead_provider, declaration_date: statement.cohort.training_starts_at + 1.day) }
  let!(:voided_declaration) { create(:declaration, :voided, statement:, cohort: statement.cohort, lead_provider: statement.lead_provider, declaration_date: statement.cohort.training_starts_at + 1.day) }
  let!(:other_voided_declaration) { create(:declaration, :voided, statement: other_statement, cohort: other_statement.cohort, lead_provider: other_statement.lead_provider, declaration_date: other_statement.cohort.training_starts_at + 1.day) }

  before { sign_in_as(create(:admin)) }

  scenario "index for a paid statement" do
    visit admin_finance_voided_index_path(statement)

    expect(page).to have_css("td:nth-child(1)", text: voided_declaration.id)
    expect(page).to have_css("td:nth-child(2)", text: voided_declaration.user.id)
    expect(page).to have_css("td:nth-child(3)", text: voided_declaration.declaration_type)
    expect(page).to have_css("td:nth-child(4)", text: voided_declaration.reload.course.name)

    expect(page).not_to have_css("td:nth-child(1)", text: eligible_declaration.id)
    expect(page).not_to have_css("td:nth-child(1)", text: other_voided_declaration.id)
  end
end
