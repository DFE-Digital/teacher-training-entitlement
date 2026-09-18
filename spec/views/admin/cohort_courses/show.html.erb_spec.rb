require "rails_helper"

RSpec.describe "admin/cohort_courses/show.html.erb", type: :view do
  subject(:rendered_page) { Capybara.string(rendered) }

  let(:admin) { create(:admin, super_admin: true) }
  let(:cohort) { create(:cohort) }
  let(:course) { create(:course) }
  let(:course_cohort) { create(:course_cohort, cohort:, course:) }
  let(:lead_provider) { create(:lead_provider) }
  let(:generic_contract_year) do
    create(
      :contract_year,
      :generic,
      course:,
      lead_provider:,
      teacher_funding: 650,
      recruitment_target: 3000,
      service_fee: 50,
      course_url: "https://example.com/course",
      email: "provider@example.com",
    )
  end
  let(:academic_year_contract_year) do
    create(
      :contract_year,
      course:,
      lead_provider:,
      academic_year: course_cohort.academic_year,
      teacher_funding: 750,
      recruitment_target: 4000,
      service_fee: 60,
    )
  end
  let(:editable_milestone) do
    create(
      :milestone,
      course:,
      declaration_type: "started",
      acceptance_window_start_offset: -7,
      acceptance_window_end_offset: 7,
    )
  end

  before do
    assign(:cohort, cohort)
    assign(:cohorts, [cohort])
    assign(:course, course)
    assign(:course_cohort, course_cohort)
    assign(:delivery_partner_counts, {})
    assign(:contract_years, [generic_contract_year, academic_year_contract_year])
    assign(:contract_financials, [academic_year_contract_year])

    without_partial_double_verification { allow(view).to receive(:current_admin).and_return(admin) }

    render
  end

  it "does not show an edit button for milestones" do
    expect(rendered_page).not_to have_link("Edit")
  end

  it "shows contract years" do
    expect(rendered_page).to have_content("Contract financials & targets")
    expect(rendered_page).to have_content(academic_year_contract_year.lead_provider.name)
    expect(rendered_page).to have_content(course_cohort.academic_year)
    expect(rendered_page).to have_content("£750.00")
    expect(rendered_page).to have_content("4,000")
    expect(rendered_page).to have_content("£60.00")
  end

  it "shows contract year contact details" do
    expect(rendered_page).to have_content("Contract year contact details")
    expect(rendered_page).to have_link("https://example.com/course", href: "https://example.com/course")
    expect(rendered_page).to have_content("provider@example.com")
  end
end
