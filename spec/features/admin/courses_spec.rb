require "rails_helper"

RSpec.feature "Listing and viewing courses", type: :feature do
  include Helpers::AdminLogin

  let(:courses_per_page) { Pagy::DEFAULT[:limit] }
  let(:admin_user) { create(:admin) }

  before do
    create_list(:course, 10)
    sign_in_as(admin_user)
  end

  context "when signed in as admin" do
    scenario "viewing the list of courses" do
      course = create(:course, name: "Course with multiple cohorts", identifier: "course-with-multiple-cohorts")

      visit(admin_courses_path)

      expect(page).to have_css("h1", text: "Courses")
      expect(page).to have_link(course.name, href: admin_course_path(course))
      expect(page).to have_css(".x-govuk-sub-navigation")
      expect(page).to have_css(".govuk-pagination__item--current", text: 1)
    end

    scenario "navigating to the second page of courses" do
      visit(admin_courses_path)

      click_on("Next")

      expect(page).to have_css("table.govuk-table tbody tr", count: 5)
      expect(page).to have_css(".govuk-pagination__item--current", text: "2")
    end

    scenario "viewing course details for all cohorts and a selected cohort" do
      visit(admin_courses_path)

      course = Course.order(name: :asc).first
      course_cohort = course.course_cohorts.max_by { |cc| cc.cohort.registration_starts_at }

      click_link(course.name)

      expect(page).to have_css("h1", text: course.name)

      within(".govuk-summary-list", match: :first) do |summary_list|
        expect(summary_list).to have_summary_item("Name", course.name)
        expect(summary_list).to have_summary_item("Course ID", course.ecf_id)
        expect(summary_list).to have_summary_item("Identifier", course.identifier)
        expect(summary_list).to have_summary_item("Description", course.description)
        expect(summary_list).not_to have_text("Cohort name")
      end

      expect(page).not_to have_css("h2", text: "Providers")
      expect(page).to have_link(course_cohort.cohort.description, href: admin_cohort_course_path(course_cohort.cohort, course))
      expect(page).to have_current_path(admin_course_path(course))
      expect(page).not_to have_link("Change")

      click_on course_cohort.cohort.description

      within(".govuk-summary-list", match: :first) do |summary_list|
        expect(summary_list).to have_summary_item("Cohort name", course_cohort.cohort.name)
        expect(summary_list).to have_summary_item("Cohort registration open", course_cohort.cohort.registration_starts_at.to_date.to_fs(:govuk))
        expect(summary_list).to have_summary_item("Course ID", course.ecf_id)
        expect(summary_list).to have_summary_item("Identifier", course.identifier)
        expect(summary_list).to have_summary_item("Description", course.description)
      end

      expect(page).to have_css("h2", text: "Providers")
      expect(page).to have_current_path(admin_cohort_course_path(course_cohort.cohort, course))
    end

    scenario "filtering courses by academic year" do
      cohort_2026_october = create(:cohort, registration_starts_at: Date.new(2026, 10, 1))
      cohort_2026_february = create(:cohort, registration_starts_at: Date.new(2026, 2, 1))
      cohort_2025 = create(:cohort, registration_starts_at: Date.new(2025, 10, 1))

      course_2026_a = build(:course, name: "Course 2026 A").tap(&:save!)
      create(:course_cohort, course: course_2026_a, cohort: cohort_2026_october, academic_year: 2026)

      course_2026_b = build(:course, name: "Course 2026 B").tap(&:save!)
      create(:course_cohort, course: course_2026_b, cohort: cohort_2026_february, academic_year: 2026)

      course_2025 = build(:course, name: "Course 2025").tap(&:save!)
      create(:course_cohort, course: course_2025, cohort: cohort_2025, academic_year: 2025)

      visit(admin_courses_path)

      click_link("2026 / 2027", exact: true)

      expect(page).to have_current_path(academic_year_admin_courses_path(2026))
      expect(page).to have_link(course_2026_a.name)
      expect(page).to have_link(course_2026_b.name)
      expect(page).not_to have_link(course_2025.name)
    end
  end

  context "when signed in as super admin" do
    let(:admin_user) { create(:super_admin) }

    scenario "editing a course name" do
      course = Course.first

      visit(admin_course_path(course))

      click_link("Edit course details")

      expect(page).to have_css("h1", text: "Edit course details")

      fill_in("Course name", with: "Updated Course Name")
      click_button("Save course details")

      expect(page).to have_css("h1", text: "Updated Course Name")
      expect(page).to have_summary_item("Name", "Updated Course Name")
    end

    scenario "editing a course with invalid input shows an error" do
      course = Course.first

      visit(edit_admin_course_path(course))

      fill_in("Course name", with: "")
      click_button("Save course details")

      expect(page).to have_css(".govuk-error-summary", text: "can't be blank")
    end
  end
end
