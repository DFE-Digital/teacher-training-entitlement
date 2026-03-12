require "rails_helper"
require "api/version"

# Swagger UI has known accessibility issues that we cannot fix
RSpec.feature "API documentation", :skip_axe, type: :feature do
  API::Version.all.each do |version|
    scenario "viewing the #{version} API documentation" do
      visit "/api/docs/#{version}"

      expect(page).to have_css(".title", text: "Teacher Training Entitlement (TTE) API")
      expect(page).to have_css(".version", text: version)
    end
  end
end
