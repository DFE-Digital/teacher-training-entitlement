require "rails_helper"

RSpec.describe "admin/cohort_courses/edit", type: :view do
  subject(:rendered_page) { Capybara.string(render) }

  let(:cohort) { create(:cohort) }
  let(:course) { create(:course, name: "Test course") }
  let(:course_cohort) do
    create(
      :course_cohort,
      cohort:,
      course:,
      participant_funding: 1000.50,
      service_fee: 250.25,
    )
  end

  before do
    assign(:cohort, cohort)
    assign(:course, course)
    assign(:course_cohort, course_cohort)
  end

  it "renders the edit course cohort form" do
    expect(rendered_page).to have_css("h1", text: "Edit course cohort")
    expect(rendered_page).to have_link("Back", href: admin_cohort_course_path(cohort, course))
    expect(rendered_page).to have_summary_item("Course", course.name)
    expect(rendered_page).to have_summary_item("Cohort", cohort.name)
    expect(rendered_page).to have_css(%(form[action="#{admin_cohort_course_path(cohort, course)}"]), count: 1)
    expect(rendered_page).to have_field("Participant funding", with: "1000.5")
    expect(rendered_page).to have_field("Service fee", with: "250.25")
    expect(rendered_page).to have_button("Save course cohort")
    expect(rendered_page).to have_link("Cancel", href: admin_cohort_course_path(cohort, course))
  end
end
