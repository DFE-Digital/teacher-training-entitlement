require "rails_helper"

RSpec.feature "viewing application history", :revisit, :versioning, type: :feature do
  include Helpers::AdminLogin

  let(:application) { create(:application) }

  before do
    sign_in_as(create(:admin))
  end

  context "when there are no changes to the application" do
    scenario "viewing application history" do
      visit admin_application_path(application)
      click_link "Application history"

      expect(page).to have_css(
        ".govuk-caption-m",
        text: "#{application.user.full_name}, #{application.course.name}, #{application.created_at.to_date.to_fs(:govuk_short)}",
      )
      expect(page).to have_css("h1", text: "Application history")

      expect(page).to have_content("No changes have been made to this application.")
    end
  end

  context "when there are changes to the application" do
    let(:application) { create(:application, :accepted, cohort:, lead_provider: LeadProvider.first) }
    let(:cohort) { create(:cohort, registration_starts_at: Date.new(2024, 4, 1)) }
    let(:older_cohort) { create(:cohort, registration_starts_at: Date.new(2023, 4, 1)) }
    let(:new_lead_provider) { create(:lead_provider, :with_courses) }

    before do
      PaperTrail.request.whodunnit = "test user"
      create(:schedule, cohort: older_cohort, course_group: application.course.course_group, identifier: application.schedule.identifier)
      Applications::ChangeCohort.new(application:, new_cohort: older_cohort).call
      Applications::ChangeFundingEligibility.new(application:, eligible_for_funding: true).call
      create(:declaration, application:)
      ::Applications::Defer.new(application: application, reason: "other", admin_user: create(:admin)).call
    end

    scenario "viewing application history" do
      visit admin_applications_history_path(application)
      expect(page).to have_css("h2", text: "Cohort changed to #{older_cohort.name}")
      expect(page).to have_css("h2", text: "Schedule changed to #{Schedule.last.name}")
      expect(page).to have_content("by test user")
      expect(page).to have_css("h2", text: "Eligible for funding changed to yes")
      expect(page).to have_css("li", text: "Status code changed to marked_funded_by_policy")
      expect(page).to have_css("h2", text: "Status changed to deferred")
      expect(page).to have_css("div.govuk-inset-text", text: "Reason for training status change: other")
    end
  end
end
