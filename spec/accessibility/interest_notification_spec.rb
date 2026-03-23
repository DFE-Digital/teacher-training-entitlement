require "rails_helper"

RSpec.describe "Interest notification accessibility", :axe, type: :feature do
  it "sign up page is accessible" do
    visit "/registration-interest/sign-up"
    expect(page).to be_axe_clean
  end

  it "confirmation page is accessible" do
    visit "/registration-interest/sign-up/confirm?email=test@example.com"
    expect(page).to be_axe_clean
  end
end
