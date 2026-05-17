require "rails_helper"

RSpec.feature "Short circuiting pages", type: :feature do
  include_context "Stub Teacher Auth Responses"

  scenario "visit /reception-registration/check-answers directly" do
    visit "/reception-registration/check-answers"
    expect(page).to have_current_path("/")
  end
end
