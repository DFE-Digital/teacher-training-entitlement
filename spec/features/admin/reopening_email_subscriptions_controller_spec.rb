require "rails_helper"

RSpec.feature "Reopening Email Subscription Management", type: :feature do
  include Helpers::AdminLogin

  let(:super_admin) { create(:super_admin) }

  before do
    sign_in_as(super_admin)
    Cohort.current
    create :email_update_subscription, email: "example@example.org", full_name: "John Doe"
  end

  scenario "unsubscribe user" do
    visit admin_settings_registration_closed_reopening_email_subscriptions_path
    expect(page).to have_text("example@example.org")
    click_link "Unsubscribe"
    click_link "Unsubscribe"
    expect(page).to have_text("Email 'example@example.org' unsubscribed")
    expect(EmailUpdateSubscription.count).to eq(0)
  end

  scenario "super admin exports users as CSV" do
    visit admin_settings_registration_closed_reopening_email_subscriptions_path
    click_link "Export all"
    expect(page.body).to eq("Name,Email\n  John Doe,example@example.org\n")
  end
end
