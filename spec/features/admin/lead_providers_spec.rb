require "rails_helper"

RSpec.feature "Listing and viewing course providers", type: :feature do
  include Helpers::AdminLogin

  let(:cohort) { create(:cohort, start_year: Date.current.year) }
  let(:course_cohort) { create(:course_cohort, cohort:, academic_year: cohort.start_year) }
  let(:contracts) { create_list(:course_cohort_provider, 5, course_cohort:) }
  let(:providers) { contracts.map(&:lead_provider) }
  let!(:delivery_partner) do
    create(:delivery_partner).tap { |dp| dp.delivery_partnerships.create!(lead_provider: providers.first, course_cohort:) }
  end

  before do
    providers.each { |lead_provider| create(:application_lead_provider, lead_provider:) }
    sign_in_as(create(:admin))
  end

  scenario "viewing the list of course providers" do
    visit(admin_lead_providers_path)

    expect(page).to have_css("h1", text: "Providers")

    providers.each do |lead_provider|
      expect(page).to have_link(lead_provider.name, href: admin_lead_provider_path(lead_provider))
    end

    lead_provider = providers.first
    click_link(lead_provider.name)

    expect(page).to have_css(".govuk-heading-l", text: lead_provider.name)

    find("#tab_delivery-partners").click
    expect(page).to have_table(with_rows: [{ "Delivery partner" => delivery_partner.name }])
  end
end
