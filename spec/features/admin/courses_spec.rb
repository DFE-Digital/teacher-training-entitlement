require "rails_helper"

RSpec.feature "Listing and viewing courses", type: :feature do
  include Helpers::AdminLogin

  let(:courses_per_page) { Pagy::DEFAULT[:limit] }
  let(:admin_user) { create(:admin) }
  let(:current_cohort) { create(:cohort, registration_starts_at: Date.new(2026, 9, 1)) }

  before do
    (courses_per_page + 5).times { |index| create_course_with_current_cohort(name: "Course #{index}") }
    sign_in_as(admin_user)
  end

  context "when signed in as admin" do
    scenario "viewing the list of courses" do
      course = create_course_with_current_cohort(name: "A Course with multiple cohorts")

      visit(admin_courses_path)

      expect(page).to have_css("h1", text: "Courses")
      expect(page).to have_text(course.name)
      expect(page).to have_css(".x-govuk-sub-navigation")
      expect(page).to have_css(".govuk-pagination__item--current", text: 1)
    end

    scenario "viewing courses not assigned to a cohort when using the default academic year filter" do
      unassigned_course = create(:course, name: "Course with no cohorts")
      unassigned_course.course_cohorts.destroy_all

      visit(admin_courses_path)

      expect(page).to have_css("h2", text: "Courses not assigned to a cohort")
      expect(page).to have_link(unassigned_course.name, href: admin_course_path(unassigned_course))

      click_link("2026 / 2027", exact: true)

      expect(page).not_to have_css("h2", text: "Courses not assigned to a cohort")
      expect(page).not_to have_link(unassigned_course.name, href: admin_course_path(unassigned_course))
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

      click_link(course_cohort.cohort.description)
      click_link(course.name)

      expect(page).to have_css("h1", text: course.name)

      within(".govuk-summary-list", match: :first) do |summary_list|
        expect(summary_list).to have_summary_item("Cohort name", course_cohort.cohort.description)
        expect(summary_list).to have_summary_item("Course ID", course.ecf_id)
        expect(summary_list).to have_summary_item("Identifier", course.identifier)
        expect(summary_list).to have_summary_item("Description", course.description)
      end

      expect(page).to have_css("h2", text: "Providers")
      expect(page).to have_current_path(cohort_admin_course_path(course, course_cohort.cohort))
    end

    scenario "viewing course details without a selected cohort" do
      course = create_course_with_current_cohort(name: "Course with contract years")
      create(
        :contract_year,
        :generic,
        :course_details,
        course:,
        lead_provider: create(:lead_provider, name: "Lead provider"),
      )

      visit(admin_course_path(course))

      expect(page).to have_css("h1", text: course.name)

      within(".govuk-summary-list", match: :first) do |summary_list|
        expect(summary_list).to have_summary_item("Course ID", course.ecf_id)
        expect(summary_list).to have_summary_item("Identifier", course.identifier)
        expect(summary_list).to have_summary_item("Short code", course.short_code)
        expect(summary_list).to have_summary_item("Description", course.description)
      end

      expect(page).to have_css("h2", text: "Contract financials & targets")
      expect(page).to have_css("h2", text: "Contract year contact details")
      expect(page).not_to have_css("h2", text: "Providers")
    end

    scenario "filtering courses by academic year" do
      cohort_2026_october = create(:cohort, registration_starts_at: Date.new(2026, 10, 1))
      cohort_2026_february = create(:cohort, registration_starts_at: Date.new(2027, 2, 1))
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
      expect(page).to have_text(course_2026_a.name)
      expect(page).to have_text(course_2026_b.name)
      expect(page).not_to have_text(course_2025.name)
    end
  end

  def create_course_with_current_cohort(name:)
    course = build(:course, name:).tap(&:save!)
    create(:course_cohort, course:, cohort: current_cohort)
    course
  end
end
