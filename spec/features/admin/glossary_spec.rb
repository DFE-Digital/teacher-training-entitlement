require "rails_helper"

RSpec.feature "Admin glossary", type: :feature do
  include Helpers::AdminLogin

  let(:admin) { create(:admin) }
  let(:super_admin) { create(:super_admin) }

  shared_examples "viewing the glossary" do
    scenario "navigating to the glossary and browsing by letter" do
      visit "/admin"

      click_link "Guidance"
      within("#side-navigation") { click_link "Glossary" }

      expect(page).to have_current_path("/admin/guidance/glossary")
      expect(page).to have_css("h1", text: "Glossary")

      within(".govuk-grid-column-three-quarters") do
        expect(page).to have_link("A", href: "#a")
        expect(page).to have_link("R", href: "#r")

        expect(page).to have_css("h2#a", text: "A")
        expect(page).to have_css("h3#academic-year-registration-periods", text: "Academic year (registration periods)")

        expect(page).to have_css("h2#r", text: "R")
        expect(page).to have_css("h3#registration-periods", text: "Registration periods")
      end
    end

    scenario "the glossary does not include deprecated fields" do
      visit "/admin/guidance/glossary"

      expect(page).not_to have_content("Funding cap")
    end
  end

  context "when signed in as an admin" do
    before { sign_in_as_admin }

    it_behaves_like "viewing the glossary"
  end

  context "when signed in as a super admin" do
    before { sign_in_as_super_admin }

    it_behaves_like "viewing the glossary"
  end
end
