require "rails_helper"

RSpec.describe "Expression of interest accessibility", :axe, type: :feature do
  it "sign up page is accessible" do
    visit registration_interest_sign_up_path
    expect(page).to be_axe_clean
  end

  it "sign up page with validation errors is accessible" do
    visit registration_interest_sign_up_path
    click_button("Confirm")
    expect(page).to be_axe_clean
  end

  it "confirmation page is accessible" do
    visit registration_interest_sign_up_confirm_path(email: "test@example.com")
    expect(page).to be_axe_clean
  end
end
