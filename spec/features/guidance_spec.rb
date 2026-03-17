require "rails_helper"

RSpec.feature "Guidance", :skip_axe, type: :feature do
  describe "Sidebar navigation" do
    it "renders sidebar navigation on guidance subpages" do
      visit "/api/guidance/get-started"

      within("#side-navigation") do
        expect(page).to have_link("Get started")
        expect(page).to have_link("How the API works")
        expect(page).to have_link("Test environments")
        expect(page).to have_link("How-to guides")
        expect(page).to have_link("Process diagrams")
        expect(page).to have_link("Release notes")
        expect(page).to have_link("Roadmap")
      end

      within("#side-navigation") { click_on "Release notes" }

      expect(page).to have_current_path("/api/guidance/release-notes", ignore_query: true)
    end
  end

  describe "GET /api/guidance" do
    it "renders the index page with masthead" do
      visit "/api/guidance"

      expect(page).to have_content("Use this API to view, submit, and update TTE training data")
      expect(page).not_to have_css("#side-navigation")
    end

    it "renders the call to action button" do
      visit "/api/guidance"

      expect(page).to have_link("Get started", href: "/api/guidance/get-started")
    end
  end

  describe "GET /api/guidance/get-started" do
    it "renders the .html page" do
      visit "/api/guidance/get-started"

      expect(page).not_to have_content("#Connect to the API")
      expect(page).to have_content("Connect to the API")
    end
  end

  describe "GET /api/guidance/test-environments" do
    it "renders the .html page" do
      visit "/api/guidance/test-environments"

      expect(page).not_to have_content("#What are the test environments")
      expect(page).to have_content("The test environments are used to test API integration without affecting real data.")
    end
  end

  describe "GET /api/guidance/release-notes" do
    it "renders the .html page" do
      visit "/api/guidance/release-notes"

      expect(page).not_to have_content("#Release notes")
      expect(page).to have_content("Release notes")
    end
  end

  it "renders a nested markdown page" do
    # to be updated with the first nested page
    visit "/api/guidance/nested/nested/test"

    expect(page).to have_content("This is a nested markdown page")
  end
end
