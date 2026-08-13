# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Statement payment", :revisit, type: :feature do
  include Helpers::AdminLogin

  let(:statement) { create(:statement, :open) }
  let(:component) { Admin::StatementDetailsComponent.new(statement:, link_to_voids: false) }

  before do
    declaration = create(:declaration, :payable, statement:)
    create(:course_cohort_provider, course_cohort: declaration.course_cohort, lead_provider: statement.lead_provider, recruitment_target: 100, teacher_funding: 900)
    statement.update!(state: "payable", deadline_date: Time.zone.yesterday)
    sign_in_as(create(:admin))
    visit(admin_finance_statement_path(statement))
  end

  scenario "marking a statement as paid" do
    expect(page).to have_css("h1", text: "#{statement.lead_provider.name}, #{statement.start_date.to_fs(:govuk_approx)}")
    click_link "Authorise for payment"

    expect(page).to have_css("h1", text: "Check #{statement.start_date.to_fs(:govuk_approx)} statement details")
    expect(page).to have_component(component)

    perform_enqueued_jobs do
      check "Yes, I'm ready to authorise this for payment", visible: :all
      click_button "Authorise for payment"
    end

    expect(page).to have_css("h1", text: "#{statement.lead_provider.name}, #{statement.start_date.to_fs(:govuk_approx)}")
    expect(page).to have_css(".govuk-tag", text: /Authorised for payment at 1?\d:\d\d[ap]m on \d?\d [A-Z][a-z]{2} 20\d\d/)
  end

  scenario "marking a statement as paid before job has run" do
    expect(page).to have_css("h1", text: "#{statement.lead_provider.name}, #{statement.start_date.to_fs(:govuk_approx)}")
    click_link "Authorise for payment"

    expect(page).to have_css("h1", text: "Check #{statement.start_date.to_fs(:govuk_approx)} statement details")
    expect(page).to have_component(component)

    check "Yes, I'm ready to authorise this for payment", visible: :all
    click_button "Authorise for payment"

    expect(page).to have_css("h1", text: "#{statement.lead_provider.name}, #{statement.start_date.to_fs(:govuk_approx)}")
    expect(page).to have_css(".govuk-notification-banner__title", text: "Authorising for payment")
    expect(page).to have_css(".govuk-notification-banner__content", text: /Requested at \d\d?:\d\d[ap]m/)
  end
end
