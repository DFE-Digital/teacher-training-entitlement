require "rails_helper"

RSpec.describe Admin::Applications::LateDeclarationsFiltersComponent, type: :component do
  subject(:rendered) { render_inline(component) }

  let!(:cohort) { create(:cohort, :unique, description: "LD April #{SecureRandom.hex(4)}") }
  let!(:other_cohort) { create(:cohort, :unique, description: "LD May #{SecureRandom.hex(4)}") }
  let!(:course) { create(:course, name: "Example Course") }
  let!(:lead_provider) { create(:lead_provider, name: "Example Provider") }
  let(:query_parameters) { {} }

  let(:component) do
    described_class.new(
      report_path: ->(params = {}) { report_path(params) },
      query_parameters:,
    )
  end

  it "renders the available filter sections" do
    expect(rendered).to have_css("h2", text: "Filters")
    expect(rendered).to have_css("h3", text: "Cohorts")
    expect(rendered).to have_css("h3", text: "Courses")
    expect(rendered).to have_css("h3", text: "Lead providers")
    expect(rendered).to have_css("h3", text: "Statuses")
  end

  it "renders filter links" do
    expect(rendered).to have_link(cohort.description, href: report_path(cohort_id: cohort.id))
    expect(rendered).to have_link(course.name, href: report_path(course_id: course.id))
    expect(rendered).to have_link(lead_provider.name, href: report_path(lead_provider_id: lead_provider.id))
    expect(rendered).to have_link("Accepted", href: report_path(status: Application::ACCEPTED))
    expect(rendered).not_to have_link("Withdrawn")
    expect(rendered).not_to have_link("Rejected")
  end

  context "when filters are selected" do
    let(:query_parameters) { { "cohort_id" => cohort.id.to_s, "page" => "2", "status" => Application::ACCEPTED } }

    it "marks the selected filters as current" do
      expect(rendered).to have_css(".x-govuk-sub-navigation__section-item--current a[aria-current='page']", text: cohort.description)
      expect(rendered).to have_css(".x-govuk-sub-navigation__section-item--current a[aria-current='page']", text: "Accepted")
    end

    it "removes the page param when changing filters" do
      expect(rendered).to have_link(
        other_cohort.description,
        href: report_path(cohort_id: other_cohort.id, status: Application::ACCEPTED),
      )
      expect(rendered).not_to have_link(
        other_cohort.description,
        href: report_path(cohort_id: other_cohort.id, page: 2, status: Application::ACCEPTED),
      )
    end
  end

private

  def report_path(params = {})
    query = params.to_query
    path = "/admin/applications/late-started-declarations"

    query.present? ? "#{path}?#{query}" : path
  end
end
