# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Statement - change deadline date", type: :feature do
  include Helpers::AdminLogin
  include ActionView::Helpers::NumberHelper

  let(:statement) { create(:statement) }

  before { sign_in_as(create(:admin)) }

  scenario "updating deadline date" do
    visit(admin_finance_statement_path(statement))
    expect(page).to have_css(".govuk-summary-card", text: "Statement summary")
    within(".govuk-summary-card", text: "Statement summary") do
      click_link "Change"
    end

    # check cancel
    expect(page).to have_link("Cancel")
    click_link "Cancel"
    expect(page).to have_current_path(admin_finance_statement_path(statement))

    # check blank date validation
    expect(page).to have_css(".govuk-summary-card", text: "Statement summary")
    within(".govuk-summary-card", text: "Statement summary") do
      click_link "Change"
    end
    click_button "Change date"

    expect(page).to have_content I18n.t("activemodel.errors.models.statements/change_deadline_date.attributes.deadline_date.blank")

    # check non-numeric characters validation
    fill_in "statements_change_deadline_date[deadline_date(3i)]", with: "x"
    fill_in "statements_change_deadline_date[deadline_date(2i)]", with: "y"
    fill_in "statements_change_deadline_date[deadline_date(1i)]", with: "z"
    click_button "Change date"

    expect(page).to have_content I18n.t("activemodel.errors.models.statements/change_deadline_date.attributes.deadline_date.blank")

    # check date validation
    new_deadline_date = statement.payment_date + 1.month
    fill_in "statements_change_deadline_date[deadline_date(3i)]", with: new_deadline_date.day
    fill_in "statements_change_deadline_date[deadline_date(2i)]", with: new_deadline_date.month
    fill_in "statements_change_deadline_date[deadline_date(1i)]", with: new_deadline_date.year

    click_button "Change date"

    expect(page).to have_content I18n.t("activemodel.errors.models.statements/change_deadline_date.attributes.deadline_date.invalid")

    # check valid date
    new_deadline_date = statement.payment_date - 1.month
    fill_in "statements_change_deadline_date[deadline_date(3i)]", with: new_deadline_date.day
    fill_in "statements_change_deadline_date[deadline_date(2i)]", with: new_deadline_date.month
    fill_in "statements_change_deadline_date[deadline_date(1i)]", with: new_deadline_date.year

    click_button "Change date"

    expect(page).to have_current_path(admin_finance_statement_path(statement))
    expect(page).to have_content("Output payment deadline changed")
  end
end
