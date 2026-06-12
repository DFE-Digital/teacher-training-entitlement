require "rails_helper"

RSpec.feature "Listing and viewing courses", type: :feature do
  include Helpers::AdminLogin

  let(:courses_per_page) { Pagy::DEFAULT[:limit] }
  let(:admin_user) { create(:admin) }

  before do
    create(:course, :npd_eirt)
    sign_in_as(admin_user)
  end

  scenario "viewing the list of courses" do
    visit(admin_courses_path)

    expect(page).to have_css("h1", text: "Courses")

    Course.order(name: :asc).limit(courses_per_page).each do |course|
      expect(page).to have_link(course.name, href: admin_course_path(course))
    end

    # Not enough courses for pagination to kick in
    # expect(page).to have_css(".govuk-pagination__item--current", text: 1)
  end

  scenario "navigating to the second page of courses", :npq do
    visit(admin_courses_path)

    click_on("Next")

    expect(page).to have_css("table.govuk-table tbody tr", count: 5)
    expect(page).to have_css(".govuk-pagination__item--current", text: "2")
  end

  scenario "viewing course details" do
    visit(admin_courses_path)

    course = Course.order(name: :asc).first
    course_cohort = course.course_cohorts.first

    click_link(course.name)

    expect(page).to have_css("h1", text: course.name)

    within(".govuk-summary-list") do |summary_list|
      expect(summary_list).to have_summary_item("Course ID", course.ecf_id)
      expect(summary_list).to have_summary_item("Identifier", course.identifier)
      expect(summary_list).to have_summary_item("Position", course.position)
      expect(summary_list).to have_summary_item("Description", course.description)
      expect(summary_list).to have_summary_item("Display", "Yes")
    end

    expect(page).to have_css("h2", text: "Course cohorts")
    expect(page).to have_table(
      with_rows: [
        {
          "Cohort" => course_cohort.cohort.description,
          "Registration start date" => course_cohort.cohort.registration_starts_at.to_fs(:govuk_short),
          "Action" => "Edit",
        },
      ],
    )
    expect(page).to have_link("Edit", href: edit_admin_cohort_path(course_cohort.cohort, redirect_to: admin_course_path(course)))
  end

  scenario "editing a cohort from the course details page returns to the course" do
    admin_user.update!(super_admin: true)
    course = Course.order(name: :asc).first
    course_cohort = course.course_cohorts.first

    visit(admin_course_path(course))
    click_link("Edit")

    expect(page).to have_current_path(edit_admin_cohort_path(course_cohort.cohort, redirect_to: admin_course_path(course)))
    expect(page).to have_link("Back", href: admin_course_path(course))

    fill_in "Description", with: "Updated cohort description"
    click_on "Update cohort"

    expect(page).to have_current_path(admin_course_path(course))
    expect(page).to have_text("Cohort updated")
    expect(course_cohort.cohort.reload.description).to eq("Updated cohort description")
  end
end
