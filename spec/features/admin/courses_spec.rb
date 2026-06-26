require "rails_helper"

RSpec.feature "Listing and viewing courses", type: :feature do
  include Helpers::AdminLogin

  let(:courses_per_page) { Pagy::DEFAULT[:limit] }
  let(:admin_user) { create(:admin) }

  before do
    create(:course, :npd_eirt)
    sign_in_as(admin_user)
  end

  context "when signed in as admin" do
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

      expect(page).to have_css(".govuk-heading-m", count: 5)
      expect(page).to have_css(".govuk-pagination__item--current", text: "2")
    end

    scenario "viewing course details" do
      visit(admin_courses_path)

      course = Course.order(name: :asc).first

      click_link(course.name)

      expect(page).to have_css("h1", text: course.name)

      within(".govuk-summary-list") do |summary_list|
        expect(summary_list).to have_summary_item("Name", course.name)
        expect(summary_list).to have_summary_item("Course ID", course.ecf_id)
        expect(summary_list).to have_summary_item("Identifier", course.identifier)
        expect(summary_list).to have_summary_item("Description", course.description)
      end

      expect(page).not_to have_link("Change")

      course.cohorts.each do |cohort|
        expect(page).to have_link(cohort.description, href: admin_course_cohort_path(course, cohort))
        within("tr", text: cohort.description) do
          expect(page).to have_css("td", text: Application.where(cohort:).count.to_s)
          expect(page).to have_text(cohort.registration_starts_at.to_date.to_fs(:govuk_short))
        end
      end
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

    scenario "adding a cohort to a course" do
      course = Course.first

      visit(admin_course_path(course))

      click_on("New cohort")

      fill_in "Description", with: "2029 to 2030"
      check "Funding cap", visible: :all
      within(".starts_at") do
        fill_in "Day", with: "2"
        fill_in "Month", with: "3"
        fill_in "Year", with: "2029"
      end
      within(".ends_at") do
        fill_in "Day", with: "31"
        fill_in "Month", with: "8"
        fill_in "Year", with: "2029"
      end
      within(".training_starts_at") do
        fill_in "Day", with: "1"
        fill_in "Month", with: "9"
        fill_in "Year", with: "2029"
      end
      within(".training_ends_at") do
        fill_in "Day", with: "31"
        fill_in "Month", with: "8"
        fill_in "Year", with: "2030"
      end

      expect { click_on "Create cohort" }.to change(course.cohorts, :count).by(1)

      cohort = course.cohorts.order(created_at: :desc, id: :desc).first
      expect(page).to have_current_path(admin_course_cohort_path(course, cohort))
      expect(page).to have_text("Cohort created")
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
