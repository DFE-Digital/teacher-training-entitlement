# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Statement", type: :feature do
  include Helpers::AdminLogin
  include ActionView::Helpers::NumberHelper

  let(:statement) { create(:statement) }

  let!(:course_cohort) do
    create(:course_cohort, course: create(:course, :npd_eirt))
  end

  before do
    create(:milestone, declaration_type: "started", course_cohort:)
    create(:milestone, declaration_type: "completed", course_cohort:)

    application = create(:application, :accepted, course: course_cohort.course, course_cohort:, lead_provider: statement.lead_provider)
    create(:declaration, state: :eligible, application:, course: course_cohort.course, course_cohort:, lead_provider: statement.lead_provider, statement:)
    create(:course_cohort_provider, course_cohort:, lead_provider: statement.lead_provider, recruitment_target: 100, teacher_funding: 900)

    sign_in_as(create(:admin))
  end

  scenario "see details" do
    visit(admin_finance_statement_path(statement))

    expect(page).to have_css("h1", text: "#{statement.lead_provider.name}, #{statement.start_date.to_fs(:govuk_approx)}")

    find("span", text: "Statement ID").click
    within("#statement-id") do
      expect(page).to have_content(statement.ecf_id)
    end

    expect(page).to have_content("Output payment date: #{statement.payment_date.to_fs(:govuk)}")
    expect(page).to have_content("Payment status: #{statement.state.humanize}")
    expect(page).to have_content("Payment run: Yes")
    expect(page).to have_content("Milestones: started")

    expect(page).to have_link("Download declarations (CSV)", href: admin_finance_assurance_report_path(statement, format: :csv))

    expect(page).not_to have_text("Standalone payments")
  end

  scenario "see the contract information for all courses of a statement" do
    visit admin_finance_statement_path(statement)
    find("span", text: "Contract Information").click

    within all(".govuk-details__text", visible: false).last do
      expect(page).to have_content(course_cohort.course.name)
    end
  end

  scenario "print views" do
    visit admin_finance_statement_path(statement)

    within(".govuk-inset-text.noprint") do
      print_providers_window = window_opened_by do
        click_link "Providers"
      end
      within_window print_providers_window do
        expect(page).to have_current_path(print_provider_admin_finance_statement_path(statement))
      end
      print_dfe_users_window = window_opened_by do
        click_link "DfE users"
      end
      within_window print_dfe_users_window do
        expect(page).to have_current_path(print_dfe_user_admin_finance_statement_path(statement))
      end
    end
  end
end
