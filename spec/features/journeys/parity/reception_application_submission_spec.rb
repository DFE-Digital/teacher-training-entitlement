require "rails_helper"

RSpec.feature "Reception registration application parity", :with_default_lead_provider, :with_default_schedules, type: :feature do
  let(:old_user) { create(:user, :with_verified_trn) }
  let(:new_user) { create(:user, :with_verified_trn) }

  scenario "old and new wizards create equivalent applications for the same path" do
    old_application = complete_ineligible_other_setting_journey(
      user: old_user,
      base_path: "/registration",
      session_key: "registration_store",
    )

    new_application = complete_ineligible_other_setting_journey(
      user: new_user,
      base_path: "/reception-registration",
      session_key: "registrations_#{new_user.id}",
    )

    expect(normalized_application(new_application)).to eq(normalized_application(old_application))
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

  def normalized_application(application)
    application.attributes.except(
      "id",
      "created_at",
      "updated_at",
      "ecf_id",
      "user_id",
      "raw_application_data",
    )
  end

end
