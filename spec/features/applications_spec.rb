require "rails_helper"

RSpec.feature "Applications", type: :feature do
  include_context "Stub Teacher Auth Responses"

  describe "applications index page" do
    scenario "when not logged in, it redirects to journey start page" do
      visit "/applications"
      expect(page).to have_current_path("/")
    end

    context "when logged in with no applications" do
      let(:user) { create(:user) }

      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      end

      scenario "redirects to the registration start page" do
        visit applications_path

        expect(page).to have_current_path(root_path)
      end
    end
  end

  describe "application show page" do
    let!(:application) { create(:application) }

    scenario "when not logged in, it redirects to journey start page" do
      visit(application_path(application.ecf_id))

      expect(page).to have_current_path("/")
    end
  end

  describe "withdrawn application" do
    let(:user) { create(:user) }
    let!(:application) { create(:application, :withdrawn, :for_cohort_starting_on, user:, registration_starts_at: Date.new(2021, 4, 1)) }

    before do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    end

    scenario "shows withdrawn status and re-registration link" do
      visit application_path(application.ecf_id)

      expect(page).to have_text("Withdrawn")
      expect(page).to have_link("submit a new registration", href: registration_wizard_show_path(step: "course-start-date"))
    end

    scenario "redirects from index to the withdrawn application" do
      visit applications_path

      expect(page).to have_current_path(application_path(application.ecf_id))
      expect(page).to have_text("Withdrawn")
    end

    context "when user also has a newer active application" do
      let!(:active_application) { create(:application, :accepted, :for_cohort_starting_on, user:, registration_starts_at: Date.new(2021, 5, 1), created_at: 1.day.from_now) }

      scenario "redirects to the most recent application" do
        visit applications_path

        expect(page).to have_current_path(application_path(active_application.ecf_id))
        expect(page).not_to have_text("Withdrawn")
      end
    end
  end
end
