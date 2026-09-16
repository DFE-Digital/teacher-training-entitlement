require "rails_helper"

RSpec.describe "admin/cohort_courses/show.html.erb", type: :view do
  subject(:rendered_page) { Capybara.string(rendered) }

  let(:admin) { create(:admin, super_admin: true) }
  let(:cohort) { create(:cohort) }
  let(:course) { create(:course) }
  let(:course_cohort) { create(:course_cohort, cohort:, course:) }

  before do
    assign(:cohort, cohort)
    assign(:cohorts, [cohort])
    assign(:course, course)
    assign(:course_cohort, course_cohort)
    assign(:delivery_partner_counts, {})

    without_partial_double_verification { allow(view).to receive(:current_admin).and_return(admin) }

    render
  end

  it "does not show an edit button for milestones" do
    expect(rendered_page).not_to have_link("Edit")
  end
end
