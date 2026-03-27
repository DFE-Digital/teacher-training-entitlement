require "rails_helper"

RSpec.feature "Applications", type: :feature do
  include_context "Stub Teacher Auth Responses"

  describe "applications index page" do
    scenario "when not logged in, it redirects to sign in" do
      visit "/applications"
      expect(page).to have_current_path("/sign-in")
    end
  end

  describe "application show page" do
    let!(:application) { create(:application) }

    scenario "when not logged in, it redirects to sign in" do
      visit(application_path(application.ecf_id))

      expect(page).to have_current_path("/sign-in")
    end
  end
end
