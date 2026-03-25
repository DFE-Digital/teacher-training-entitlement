require "rails_helper"

RSpec.describe "Applications accessibility", :axe, type: :feature do
  let(:user) { create(:user, :with_get_an_identity_id) }
  let(:application) { create(:application, user:) }

  before do
    page.set_rack_session("user_id" => user.id)
  end

  it "applications index page with no applications is accessible" do
    visit "/applications"
    expect(page).to be_axe_clean
  end

  it "applications index page with applications is accessible" do
    application
    visit "/applications"
    expect(page).to be_axe_clean
  end

  it "application show page is accessible" do
    visit application_path(application.ecf_id)
    expect(page).to be_axe_clean
  end
end
