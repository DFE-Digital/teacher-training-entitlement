require "rails_helper"

RSpec.feature "Building a course", type: :feature do
  include Helpers::AdminLogin

  let!(:lead_provider) { create(:lead_provider, name: "A Lead Provider") }
  let(:super_admin) { create(:super_admin) }

  before { sign_in_as_super_admin }

  scenario "creating a course with the default milestones and minimal provider data" do
    visit admin_course_builder_path(step: "course-details")

    fill_in "Name", with: "Minimal course"
    select "Reception", from: "Course group"
    click_on "Continue"

    fill_in "milestones-started-payment-percentage-field", with: "60"
    fill_in "milestones-completed-payment-percentage-field", with: "40"
    click_on "Continue"

    find("label", text: lead_provider.name).click
    click_on "Continue"

    click_on "Continue"

    expect(page).to have_css("h1", text: "Check course configuration")
    expect(page).to have_text("Started and Completed")
    expect(page).to have_text(lead_provider.name)

    click_button "Create course"

    course = Course.find_by!(name: "Minimal course")
    expect(course.milestones.pluck(:declaration_type, :payment_percentage)).to contain_exactly(
      [Milestone::STARTED, BigDecimal("0.6")],
      [Milestone::COMPLETED, BigDecimal("0.4")],
    )
    expect(page).to have_current_path(admin_settings_path)
    expect(page).to have_text("Course created successfully")
  end
end
