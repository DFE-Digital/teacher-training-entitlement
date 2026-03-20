require "rails_helper"

RSpec.feature "Sessions: integration with TeacherAuth", type: :feature do
  include Helpers::JourneyHelper

  include_context "Stub Teacher Auth Responses"

  before do
    allow(User).to receive(:find_by).and_return(FactoryBot.create(:user))
  end

  scenario "One Login header links are visible for logged-in users" do
    visit "/"

    expect(page).to have_button("Sign out")
    expect(page).to have_link("GOV.UK One Login", href: ENV.fetch("ONE_LOGIN_HOME_URL"))
  end
end
