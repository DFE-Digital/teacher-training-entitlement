require "rails_helper"

RSpec.feature "Managing cohorts", :ecf_api_disabled, type: :feature do
  include Helpers::AdminLogin
  include Helpers::FileHelper

  let(:admin) { create :admin }
  let!(:cohort) { Cohort.find_by(identifier: "2026-April") || create(:cohort, start_year: 2026, registration_starts_at: Date.new(2026, 4, 1)) }

  let(:new_button_text)    { "New cohort" }
  let(:edit_button_text)   { "Edit cohort details" }
  let(:delete_button_text) { "Delete cohort" }
  let(:download_contracts_button_text) { "Download contracts CSV" }

  before do
    (2026..2028).each { create :cohort, start_year: _1 }

    sign_in_as admin
  end

  scenario "listing cohorts" do
    visit_index

    expect(Cohort.count).to be_positive
    expected = Cohort.order_by_latest.map { |c| [c.description, c.registration_starts_at.to_date.to_fs(:govuk), "Yes"] }
    expect(page).to have_table(rows: expected)
  end

  scenario "viewing details" do
    navigate_to_cohort

    expect(page).to have_css("h1", text: "Cohort April 2026")

    within(".govuk-summary-list") do |summary_list|
      expect(summary_list).to have_summary_item("Name", "2026")
      expect(summary_list).to have_summary_item("Start year", "2026")
      expect(summary_list).to have_summary_item("Registration start date", "1 April 2026")
      expect(summary_list).to have_summary_item("Funding cap", "Yes")
    end
  end

  context "when logged in as a super admin" do
    before do
      admin.update! super_admin: true
    end

    scenario "creation" do
      partnerships = create_list(:delivery_partnership, 3, cohort: Cohort.order_by_latest.first)
      visit_index
      click_on new_button_text

      expect(page).to have_css("a.govuk-back-link[href$='#{admin_cohorts_path}']", text: "Back")

      fill_in "Description", with: "2029 to 2030"
      fill_in "Start year", with: "2029"
      check "Funding cap", visible: :all
      within(".starts_at") do
        fill_in "Day", with: "2"
        fill_in "Month", with: "3"
        fill_in "Year", with: "2029"
      end

      perform_enqueued_jobs do
        expect { click_on "Create cohort" }.to change(Cohort, :count).by(1)
      end

      cohort = Cohort.order(created_at: :desc, id: :desc).first
      expect(cohort.identifier).to eq("2029-March")
      expect(cohort.name).to eq("2029 to 2030")
      expect(cohort.description).to eq("2029 to 2030")
      expect(cohort.start_year).to be(2029)
      expect(cohort.funding_cap).to be(true)
      expect(cohort.registration_starts_at).to eq(Date.new(2029, 3, 2))
      expect(cohort.delivery_partnerships.pluck(:delivery_partner_id, :lead_provider_id)).to eq(partnerships.pluck(:delivery_partner_id, :lead_provider_id))
    end

    scenario "editing" do
      cohort.update! funding_cap: false

      navigate_to_cohort
      click_on edit_button_text

      new_description = "2025 to 2026 #{rand(100)}"
      fill_in "Description", with: new_description
      fill_in "Start year", with: "2025"
      check "Funding cap", visible: :all
      within(".starts_at") do
        fill_in "Day", with: "6"
        fill_in "Month", with: "5"
        fill_in "Year", with: "2025"
      end
      expect { click_on "Update cohort" }.not_to(change(Cohort, :count))
      expect(page).to have_text("Cohort updated")

      cohort.reload

      expect(cohort.identifier).to eq("2025-May")
      expect(cohort.name).to eq(new_description)
      expect(cohort.description).to eq(new_description)
      expect(cohort.start_year).to be(2025)
      expect(cohort.funding_cap).to be(true)
      expect(cohort.registration_starts_at.to_date).to eq(Date.new(2025, 5, 6))
    end

    scenario "deletion" do
      navigate_to_cohort
      click_on delete_button_text

      expect { click_on "Confirm" }.to change(Cohort, :count).by(-1)
    end

    scenario "downloading contracts CSV" do
      LeadProvider.find_each do |lead_provider|
        statement = create(:statement, cohort:, lead_provider:)

        Course.find_each do |course|
          create(:contract, statement:, course:, contract_template: create(:contract_template))
        end
      end

      visit download_contracts_admin_cohort_path(cohort)
      csv_file = "#{Capybara.save_path}/#{cohort.start_year}_cohort_contracts.csv"
      wait_for_file_to_be_created(csv_file)
      csv = CSV.read(csv_file)
      expect(csv.count).to eq(ContractTemplate.count + 1)
    end
  end

  context "when logged in as a normal admin" do
    scenario "cannot create" do
      visit_index
      expect(page).not_to have_link(new_button_text)
    end

    scenario "cannot edit" do
      navigate_to_cohort
      expect(page).not_to have_link(edit_button_text)
    end

    scenario "cannot delete" do
      navigate_to_cohort
      expect(page).not_to have_link(delete_button_text)
    end

    scenario "cannot download contracts CSV" do
      navigate_to_cohort
      expect(page).not_to have_link(download_contracts_button_text)
    end
  end

private

  def visit_index
    visit admin_cohorts_path
  end

  def navigate_to_cohort
    visit_index
    click_on cohort.description
  end
end
