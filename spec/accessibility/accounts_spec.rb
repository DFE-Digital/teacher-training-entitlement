require "rails_helper"

RSpec.describe "Accounts accessibility", :axe, type: :feature do
  let(:user) { create(:user, :with_get_an_identity_id) }
  let(:application) { create(:application, user:) }

  before do
    page.set_rack_session("user_id" => user.id)
  end

  it "account page with no applications is accessible" do
    visit "/account"
    expect(page).to be_axe_clean
  end

  it "account page with applications is accessible" do
    application
    visit "/account"
    expect(page).to be_axe_clean
  end

  it "user registration page is accessible" do
    visit accounts_user_registration_path(application)
    expect(page).to be_axe_clean
  end
end
