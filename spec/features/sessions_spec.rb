require "rails_helper"

RSpec.feature "Sessions", type: :feature do
  let(:otp_code) { "123456" }

  include_context "Stub Teacher Auth Responses"

  scenario "signing in when user does not exist" do
    visit "/sign-in"
    expect(page).to be_accessible
    expect(page).to have_content("Sign in")
    page.fill_in "What's your email address?", with: "user@example.com"
    page.click_button "Sign in"

    expect(page).to be_accessible
    expect(page).to have_content("Check your email")
    expect(ActionMailer::Base.deliveries.size).to be_zero
  end

  scenario "signing in when admin exists" do
    allow_any_instance_of(OtpCodeGenerator).to receive(:call).and_return(otp_code)
    FactoryBot.create(:admin, email: "user@example.com")

    visit "/sign-in"
    expect(page).to have_content("Sign in")
    page.fill_in "What’s your email address?", with: " User@example.com "
    page.click_button "Sign in"

    expect(page).to have_content("Check your email")

    page.fill_in "Enter your code", with: otp_code
    page.click_button "Sign in"

    expect(page).to have_content("Dashboards")
  end
end
