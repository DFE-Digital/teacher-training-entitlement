require "rails_helper"

RSpec.feature "Listing and viewing courses", type: :feature do
  include Helpers::AdminLogin

  let(:courses_per_page) { Pagy::DEFAULT[:limit] }
  let(:admin_account) { create(:admin) }

  before do
    create(:course, :npd_eirt)
    sign_in_as(admin_account)
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
    expect(page).to have_content(course_cohort.cohort.name)
    expect(page).to have_content(course_cohort.schedule.name)
  end

  context "when logged in as a super admin" do
    let(:admin_account) { create(:super_admin) }

    scenario "adding and removing providers from a course cohort" do
      course = Course.order(name: :asc).first
      course_cohort = course.course_cohorts.first
      existing_lead_provider = course_cohort.lead_providers.first
      lead_provider = create(:lead_provider, name: "A provider to add")

      visit(admin_course_path(course))
      click_link("Add/Remove providers")

      uncheck existing_lead_provider.name, visible: :all
      check lead_provider.name, visible: :all
      click_button "Save providers"

      expect(page).to have_content("Course cohort providers updated")
      expect(course_cohort.lead_providers.reload).to contain_exactly(lead_provider)
    end

    scenario "cannot add or remove providers from a course cohort after registration has ended" do
      course = Course.order(name: :asc).first
      open_course_cohort = course.course_cohorts.first
      closed_cohort = create(:cohort, :unique, registration_ends_at: 1.day.ago)
      closed_course_cohort = create(:course_cohort, course:, cohort: closed_cohort)

      visit(admin_course_path(course))

      within("tr", text: open_course_cohort.cohort.name) do
        expect(page).to have_link("Add/Remove providers")
      end

      within("tr", text: closed_course_cohort.cohort.name) do
        expect(page).not_to have_link("Add/Remove providers")
      end
    end
  end
end
