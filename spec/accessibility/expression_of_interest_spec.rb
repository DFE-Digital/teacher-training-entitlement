require "rails_helper"

RSpec.describe "Expression of interest accessibility", :axe, type: :feature do
  it "checks expressions of interest page" do
    visit registration_interest_sign_up_path
    expect(page).to be_axe_clean

    click_button("Confirm")
    expect(page).to be_axe_clean

    fill_in "questionnaires_registration_interest_notification[email]", with: "alsa@email.com"
    click_button("Confirm")
    expect(page).to be_axe_clean
  end
end
