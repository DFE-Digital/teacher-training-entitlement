require "rails_helper"

RSpec.feature "Listing and viewing courses", type: :feature do
  include Helpers::AdminLogin

  let(:courses_per_page) { Pagy::DEFAULT[:limit] }

  before do
    create(:course, :npd_eirt)
  end

  context "when signed in as admin" do
    before do
      sign_in_as(create(:admin))
    end

    scenario "viewing the list of courses" do
      latest_cohort = create(:cohort, :unique, registration_starts_at: Date.new(2028, 1, 1))
      older_cohort = create(:cohort, :unique, registration_starts_at: Date.new(2027, 1, 1))
      course = create(:course, name: "Course with multiple cohorts", identifier: "course-with-multiple-cohorts")

      create(:course_cohort, course:, cohort: older_cohort)
      create(:course_cohort, course:, cohort: latest_cohort)

      visit(admin_courses_path)

      expect(page).to have_css("h1", text: "Courses")
      expect(page).to have_link(course.name, href: admin_cohort_course_path(latest_cohort, course))
      expect(page).to have_css(".x-govuk-sub-navigation")

      # Not enough courses for pagination to kick in
      # expect(page).to have_css(".govuk-pagination__item--current", text: 1)
    end

    scenario "navigating to the second page of courses", :npq do
      visit(admin_courses_path)

      click_on("Next")

      expect(page).to have_css("table.govuk-table tbody tr", count: 5)
      expect(page).to have_css(".govuk-pagination__item--current", text: "2")
    end

    scenario "viewing course details for the latest cohort" do
      visit(admin_courses_path)

      course = Course.order(name: :asc).first
      course_cohort = course.course_cohorts.max_by { |cc| cc.cohort.registration_starts_at }

      click_link(course.name)

      expect(page).to have_css("h1", text: course.name)
      expect(page).to have_current_path(admin_cohort_course_path(course_cohort.cohort, course))

      within(".govuk-summary-list", match: :first) do |summary_list|
        expect(summary_list).to have_summary_item("Cohort name", course_cohort.cohort.name)
        expect(summary_list).to have_summary_item("Cohort registration open", course_cohort.cohort.registration_starts_at.to_date.to_fs(:govuk))
        expect(summary_list).to have_summary_item("Course ID", course.ecf_id)
        expect(summary_list).to have_summary_item("Identifier", course.identifier)
        expect(summary_list).to have_summary_item("Description", course.description)
      end

      expect(page).to have_css("h2", text: "Schedule")
      expect(page).to have_css("h2", text: "Providers")
    end

    scenario "viewing course details for all cohorts" do
      course = Course.first

      visit(admin_course_path(course))

      expect(page).to have_css("h1", text: course.name)

      within(".govuk-summary-list") do |summary_list|
        expect(summary_list).to have_summary_item("Name", course.name)
        expect(summary_list).to have_summary_item("Course ID", course.ecf_id)
        expect(summary_list).to have_summary_item("Identifier", course.identifier)
        expect(summary_list).to have_summary_item("Position", course.position)
        expect(summary_list).to have_summary_item("Description", course.description)
        expect(summary_list).to have_summary_item("Display", "Yes")
      end

      expect(page).not_to have_link("Change")
    end
  end

  context "when signed in as super admin" do
    before do
      sign_in_as(create(:super_admin))
    end

    scenario "editing a course name" do
      course = Course.first

      visit(admin_course_path(course))

      click_link("Change name")

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
