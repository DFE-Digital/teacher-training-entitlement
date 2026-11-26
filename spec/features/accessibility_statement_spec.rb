require "rails_helper"

RSpec.feature "Accessibility Statement", type: :feature do
  include_context "Stub Teacher Auth Responses"

  scenario "View info about accessibility statement" do
    visit "/"
    click_link("Accessibility")

    expect(page).to have_text("Accessibility statement")
  end
end
