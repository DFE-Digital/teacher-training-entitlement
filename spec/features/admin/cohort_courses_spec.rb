require "rails_helper"

RSpec.feature "Adding a course to a cohort", type: :feature do
  include Helpers::AdminLogin

  let(:super_admin) { create(:super_admin) }
  let(:cohort) { create(:cohort, registration_starts_at: Date.new(2024, 5, 1)) }
  let!(:course) { create(:course, name: "Course to add", identifier: "course-to-add") }
  let!(:lead_provider_one) { create(:lead_provider, name: "Provider One") }
  let!(:lead_provider_two) { create(:lead_provider, name: "Provider Two") }
  let!(:delivery_partner) { create(:delivery_partner, lead_providers: [lead_provider_one]) }

  before { sign_in_as_super_admin }

  def fill_in_training_starts_at(day:, month:, year:)
    fill_in "course_cohort_training_starts_at_3i", with: day
    fill_in "course_cohort_training_starts_at_2i", with: month
    fill_in "course_cohort_training_starts_at_1i", with: year
  end

  def lead_provider_conditional_selector(lead_provider)
    "#course-cohort-lead-provider-#{lead_provider.id}-id-#{lead_provider.id}-conditional"
  end

  scenario "adding a course with a selected lead provider and funding details" do
    visit new_admin_cohort_course_path(cohort)

    select course.name, from: "Course"
    fill_in_training_starts_at(day: "1", month: "9", year: "2025")

    check lead_provider_one.name, visible: :all
    within(lead_provider_conditional_selector(lead_provider_one)) do
      fill_in "Teacher funding", with: "1000"
      fill_in "Recruitment target", with: "50"
    end

    click_on "Add course"

    expect(page).to have_content("Course added")

    course_cohort = cohort.course_cohorts.find_by(course:)
    expect(course_cohort).to be_present

    course_cohort_provider = course_cohort.course_cohort_providers.find_by(lead_provider: lead_provider_one)
    expect(course_cohort_provider).to be_present
    expect(course_cohort_provider.teacher_funding).to eq(1000)
    expect(course_cohort_provider.recruitment_target).to eq(50)

    expect(course_cohort.delivery_partnerships.find_by(lead_provider: lead_provider_one, delivery_partner:)).to be_present

    # the unchecked provider is not added
    expect(course_cohort.course_cohort_providers.find_by(lead_provider: lead_provider_two)).to be_nil
  end

  scenario "adding a course with a selected lead provider but no funding details" do
    visit new_admin_cohort_course_path(cohort)

    select course.name, from: "Course"
    fill_in_training_starts_at(day: "1", month: "9", year: "2025")

    check lead_provider_one.name, visible: :all

    click_on "Add course"

    expect(page).to have_content("Course added")

    course_cohort = cohort.course_cohorts.find_by(course:)
    course_cohort_provider = course_cohort.course_cohort_providers.find_by(lead_provider: lead_provider_one)

    expect(course_cohort_provider).to be_present
    expect(course_cohort_provider.teacher_funding).to be_nil
    expect(course_cohort_provider.recruitment_target).to be_nil
  end
end
