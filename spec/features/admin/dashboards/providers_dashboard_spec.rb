require "rails_helper"

RSpec.feature "Viewing the providers dashboard", type: :feature do
  include Helpers::AdminLogin

  let(:test_provider) { create(:lead_provider, name: "Test Provider") }
  let(:current_cohort) { create(:cohort, :current) }

  let :previous_cohort do
    create(:cohort, registration_starts_at: (current_cohort.registration_starts_at - 1.year))
  end

  before do
    sign_in_as(create(:admin))

    create_list(:application, 2, :for_cohort_starting_on, registration_starts_at: current_cohort.registration_starts_at, lead_provider: test_provider)
    create(:application, :for_cohort_starting_on, registration_starts_at: previous_cohort.registration_starts_at, lead_provider: test_provider)
  end

  scenario "viewing the providers dashboard table" do
    visit(admin_dashboard_path("providers-dashboard"))

    expect(page).to have_css("h1", text: "Providers dashboard")
    expect(page).to have_css("th", text: "Provider")
    expect(page).to have_css("th", text: "Applications")
    expect(page).to have_content("3")
  end

  scenario "filtering providers dashboard by a single cohort updates application counts" do
    visit admin_dashboard_path("providers-dashboard")

    select previous_cohort.description, from: "Search by cohort"
    click_button "Search"

    expect(page).to have_content("Test Provider")
    expect(page).to have_content("1")
  end
end
