require "rails_helper"

RSpec.feature "admin", :rack_test_driver, type: :feature do
  include Helpers::AdminLogin
  include_context "Stub Teacher Auth Responses"

  let(:admin) { create(:admin) }
  let(:super_admin) { create(:super_admin) }
  let(:separation_admin_link_text) { "Separation Admin" }

  before do
    create(:cohort, :current)
  end

  scenario "regular admins cannot see links that super admins can" do
    sign_in_as_admin
    expect(page).not_to have_link("Feature flags")
  end
end
