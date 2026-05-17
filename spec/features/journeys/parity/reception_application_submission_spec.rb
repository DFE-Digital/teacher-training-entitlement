require "rails_helper"

RSpec.feature "Reception registration application submission", :with_default_lead_provider, :with_default_schedules, type: :feature do
  let(:user) { create(:user, :with_verified_trn) }

  scenario "creates an application for an ineligible other-setting path" do
    application = complete_ineligible_other_setting_journey(
      user:,
      base_path: "/reception-registration",
      session_key: "registrations_#{user.id}",
    )

    expect(application).to have_attributes(
      user:,
      eligible_for_funding: false,
      funding_eligiblity_status_code: "ineligible_setting",
      funding_choice: "self",
      institution: nil,
      teacher_catchment: "england",
      work_setting: "other",
      works_in_school: false,
      works_in_childcare: false,
      status: Application::PENDING,
    )
  end

  def complete_ineligible_other_setting_journey(user:, base_path:, session_key:)
    page.set_rack_session("user_id" => user.id, session_key => {})

    visit "#{base_path}/course-start-date"
    page.choose("Yes", visible: :all)
    page.click_button("Continue")

    expect(page).to have_current_path("#{base_path}/choose-your-course")
    page.click_button("Continue")

    expect(page).to have_current_path("#{base_path}/choose-your-provider")
    page.choose(LeadProvider.first.name, visible: :all)
    page.click_button("Continue")

    expect(page).to have_current_path("#{base_path}/teacher-catchment")
    page.choose("Yes", visible: :all)
    page.click_button("Continue")

    expect(page).to have_current_path("#{base_path}/work-setting")
    page.choose("Other", visible: :all)
    page.click_button("Continue")

    expect(page).to have_current_path("#{base_path}/ineligible-for-funding")
    page.click_link("Continue")

    expect(page).to have_current_path("#{base_path}/funding-your-course")
    page.choose("I am paying", visible: :all)
    page.click_button("Continue")

    expect(page).to have_current_path("#{base_path}/share-provider")
    page.check("Yes, I agree to share my information", visible: :all)
    page.click_button("Continue")

    expect(page).to have_current_path("#{base_path}/check-answers")
    expect(page).to have_text("Check your answers and submit")
    page.click_button("Submit")

    user.applications.order(:created_at).last.tap do |application|
      expect(application).to be_present
    end
  end

end
