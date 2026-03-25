# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Administering API Test Scenarios", :revisit, type: :feature do
  include Helpers::AdminLogin

  let(:admin) { create(:admin) }
  let(:super_admin) { create(:super_admin) }
  let!(:lead_provider) { create(:lead_provider) }
  let!(:other_lead_provider) { create(:lead_provider) }

  before do
    create(:school)
    allow(Rails).to receive(:env).and_return("sandbox".inquiry)
  end

  scenario "regular admin cannot access API Test Scenarios" do
    sign_in_as_admin
    visit admin_path

    expect(page).not_to have_link("API Test Scenarios")

    visit admin_api_test_scenarios_path
    expect(page).to have_content("Unauthorized")
  end

  scenario "super admin can view the API Test Scenarios page" do
    sign_in_as_super_admin
    visit admin_path

    click_link "API Test Scenarios"
    expect(page).to have_current_path(admin_api_test_scenarios_path)
    expect(page).to have_css("h1.govuk-heading-l", text: "API Test Scenarios")
  end

  scenario "super admin can see list of providers with their seeding status" do
    sign_in_as_super_admin
    visit admin_api_test_scenarios_path

    expect(page).to have_content(lead_provider.name)
    expect(page).to have_css("strong.govuk-tag.govuk-tag--grey", text: "Not seeded")
    expect(page).to have_content("0") # Applications count
  end

  scenario "super admin can seed test data for a provider" do
    sign_in_as_super_admin
    visit admin_api_test_scenarios_path

    accept_confirm do
      within("tr", text: lead_provider.name) do
        click_button "Seed data"
      end
    end

    expect(page).to have_current_path(admin_api_test_scenarios_path)
    expect(page).to have_content("Success")
    expect(page).to have_content("API test scenarios seeded successfully for #{lead_provider.name}")
    expect(page).to have_content("Created 12 applications")
  end

  scenario "super admin sees updated status after seeding" do
    sign_in_as_super_admin
    visit admin_api_test_scenarios_path

    accept_confirm do
      within("tr", text: lead_provider.name) do
        click_button "Seed data"
      end
    end

    expect(page).to have_css("strong.govuk-tag.govuk-tag--green", text: "Seeded")
    expect(page).to have_content("12") # Applications count
    expect(page).to have_button("Re-seed data")
  end

  scenario "super admin can re-seed test data for a provider" do
    # Seed data first
    ValidTestDataGenerators::APITestScenariosSeeder.new(lead_provider: lead_provider).call

    sign_in_as_super_admin
    visit admin_api_test_scenarios_path

    expect(page).to have_css("strong.govuk-tag.govuk-tag--green", text: "Seeded")
    expect(page).to have_content("12")

    accept_confirm do
      within("tr", text: lead_provider.name) do
        click_button "Re-seed data"
      end
    end

    expect(page).to have_content("Success")
    expect(page).to have_content("API test scenarios seeded successfully")
    expect(page).to have_content("12")
  end

  scenario "super admin sees confirmation dialog when seeding" do
    sign_in_as_super_admin
    visit admin_api_test_scenarios_path

    # With Capybara, we need to accept the confirm dialog
    accept_confirm do
      within("tr", text: lead_provider.name) do
        click_button "Seed data"
      end
    end

    expect(page).to have_content("Success")
  end

  scenario "super admin sees confirmation dialog when re-seeding" do
    # Seed data first
    ValidTestDataGenerators::APITestScenariosSeeder.new(lead_provider: lead_provider).call

    sign_in_as_super_admin
    visit admin_api_test_scenarios_path

    accept_confirm do
      within("tr", text: lead_provider.name) do
        click_button "Re-seed data"
      end
    end

    expect(page).to have_content("Success")
  end

  scenario "super admin can see multiple providers and their individual statuses" do
    ValidTestDataGenerators::APITestScenariosSeeder.new(lead_provider:).call

    sign_in_as_super_admin
    visit admin_api_test_scenarios_path

    within("tr", text: lead_provider.name) do
      expect(page).to have_css("strong.govuk-tag.govuk-tag--green", text: "Seeded")
      expect(page).to have_content("12")
      expect(page).to have_button("Re-seed data")
    end

    within("tr", text: other_lead_provider.name) do
      expect(page).to have_css("strong.govuk-tag.govuk-tag--grey", text: "Not seeded")
      expect(page).to have_content("0")
      expect(page).to have_button("Seed data")
    end
  end

  scenario "super admin can link to provider page" do
    sign_in_as_super_admin
    visit admin_api_test_scenarios_path

    expect(page).to have_link(lead_provider.name, href: admin_lead_provider_path(lead_provider))
  end

  scenario "API Test Scenarios link only appears in sandbox/development/review" do
    sign_in_as_super_admin
    visit admin_path

    expect(page).to have_link("API Test Scenarios")

    # Simulate production environment
    allow(Rails).to receive(:env).and_return("production".inquiry)
    visit admin_path

    expect(page).not_to have_link("API Test Scenarios")
  end

  scenario "super admin cannot access page in production environment" do
    allow(Rails).to receive(:env).and_return("production".inquiry)

    sign_in_as_super_admin
    visit admin_api_test_scenarios_path

    expect(page).to have_current_path(admin_path)
  end

  scenario "page shows warning about deleting existing data" do
    sign_in_as_super_admin
    visit admin_api_test_scenarios_path

    expect(page).to have_css(".govuk-warning-text")
    expect(page).to have_content("Running this will delete any existing test data for the selected provider and cohort year")
  end

  scenario "seeded data persists across page reloads" do
    sign_in_as_super_admin
    visit admin_api_test_scenarios_path

    accept_confirm do
      within("tr", text: lead_provider.name) do
        click_button "Seed data"
      end
    end

    expect(page).to have_css("strong.govuk-tag.govuk-tag--green", text: "Seeded")

    # Reload the page
    visit admin_api_test_scenarios_path

    within("tr", text: lead_provider.name) do
      expect(page).to have_css("strong.govuk-tag.govuk-tag--green", text: "Seeded")
      expect(page).to have_content("12")
    end
  end
end
