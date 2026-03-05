require "rails_helper"

RSpec.feature "Sessions: integration with TeacherAuth", type: :feature do
  include Helpers::JourneyHelper

  include_context "Stub Teacher Auth Responses"

  before do
    allow(User).to receive(:find_by).and_return(FactoryBot.create(:user))
  end

  scenario "TeacherAuth header links are only visible for logged-in users" do
    skip "Update once TeacherAuth account link is implemented"

    visit "/"

    expect(page).to have_link("Sign out", href: /\/sign-out/)
    expect(page).to have_link("DfE Identity account", href: /\/account\?client_id=npq&redirect_uri=[^&]+&sign_out_uri=[^&]+/)
  end
end
