require "rails_helper"

RSpec.feature "Sessions", type: :feature do
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
    admin = FactoryBot.create(:admin, email: "user@example.com")

    visit "/sign-in"
    expect(page).to have_content("Sign in")
    page.fill_in "What’s your email address?", with: " User@example.com "
    page.click_button "Sign in"

    expect(page).to have_content("Check your email")

    page.fill_in "Enter your code", with: admin.reload.otp_hash
    page.click_button "Sign in"

    expect(page).to have_content("Dashboards")
  end

  scenario "when locked out shows request new code link" do
    admin = FactoryBot.create(:admin, email: "user@example.com")

    visit "/sign-in"
    page.fill_in "What’s your email address?", with: admin.email
    page.click_button "Sign in"

    admin.update!(otp_failed_attempts: AdminUser::MAX_OTP_ATTEMPTS - 1)

    page.fill_in "Enter your code", with: "WRONG123"
    page.click_button "Sign in"

    expect(page).to have_content("locked out")
    expect(page).to have_link("Request a new code", href: sign_in_path)
    expect(page).not_to have_field("Enter your code")
  end
end
