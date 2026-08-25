require "rails_helper"

RSpec.describe "admin/cohort_courses/show.html.erb", type: :view do
  subject(:rendered_page) { Capybara.string(rendered) }

  let(:admin) { create(:admin, super_admin: true) }
  let(:cohort) { create(:cohort) }
  let(:course) { create(:course) }
  let(:course_cohort) { create(:course_cohort, cohort:, course:) }
  let(:editable_milestone) do
    create(
      :milestone,
      course_cohort:,
      declaration_type: "started",
      acceptance_window_start_date: 1.week.ago,
      acceptance_window_end_date: 1.week.from_now,
    )
  end
  let(:non_editable_milestone) do
    create(
      :milestone,
      course_cohort:,
      declaration_type: "completed",
      acceptance_window_start_date: 4.weeks.ago,
      acceptance_window_end_date: 1.week.ago,
    )
  end

  before do
    editable_milestone
    non_editable_milestone

    assign(:cohort, cohort)
    assign(:cohorts, [cohort])
    assign(:course, course)
    assign(:course_cohort, course_cohort)
    assign(:delivery_partner_counts, {})

    without_partial_double_verification { allow(view).to receive(:current_admin).and_return(admin) }

    render
  end

  it "shows an edit button for editable milestones" do
    expect(rendered_page).to have_link(
      "Edit",
      href: edit_admin_cohort_course_milestone_path(cohort, course, editable_milestone),
    )
  end

  it "does not show an edit button for non-editable milestones" do
    expect(rendered_page).not_to have_link(
      "Edit",
      href: edit_admin_cohort_course_milestone_path(cohort, course, non_editable_milestone),
    )
  end
end
