require "rails_helper"

RSpec.feature "Sessions", type: :feature do
  let(:otp_code) { "ABCD2345" }

  include_context "Stub Teacher Auth Responses"

  scenario "signing in when user does not exist" do
    visit "/sign-in"
    expect(page).to have_content("Sign in")
    page.fill_in "What’s your email address?", with: "user@example.com"
    page.click_button "Sign in"

    expect(page).to have_content("Check your email")
    expect(ActionMailer::Base.deliveries.size).to be_zero
  end

  scenario "signing in when admin exists" do
    allow(OTP).to receive(:generate).and_return(OTP.new(code: otp_code, expires_at: 10.minutes.from_now))
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

  scenario "signing in with a lowercase code with look-alike characters" do
    allow(OTP).to receive(:generate).and_return(OTP.new(code: "0123ABCD", expires_at: 10.minutes.from_now))
    FactoryBot.create(:admin, email: "user@example.com")

    visit "/sign-in"
    page.fill_in "What’s your email address?", with: "user@example.com"
    page.click_button "Sign in"
    page.fill_in "Enter your code", with: "o123abcd"
    page.click_button "Sign in"

    expect(page).to have_content("Dashboards")
  end
end
