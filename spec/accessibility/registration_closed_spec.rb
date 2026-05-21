require "rails_helper"

RSpec.describe "Registration closed accessibility", :axe, type: :feature do
  it "registration closed page is accessible" do
    visit registration_closed_path
    expect(page).to be_axe_clean
  end

  it "registration closed change page is accessible" do
    visit change_registration_closed_path
    expect(page).to be_axe_clean
  end
end
