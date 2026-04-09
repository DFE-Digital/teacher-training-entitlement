require "rails_helper"

RSpec.feature "Change provider", type: :feature do
  let(:application) { create(:application, :pending) }
  let(:another_provider) { create(:lead_provider) }

  before do
    page.set_rack_session("user_id" => application.user.id)
    create(:course_cohort, lead_provider: another_provider,
                           course: application.course,
                           cohort: application.cohort)
  end

  it do
    #
    # Start page
    #
    visit application_change_provider_start_index_path(application.ecf_id)

    expect(page).to have_text("Register with a different provider for the #{application.course.name}")

    choose(I18n.t("applications.change_provider.start.form.yes_option"), visible: :all)

    click_button("Continue")

    expect(page).to have_current_path(application_change_provider_providers_path(application.ecf_id))

    #
    # Providers page
    #
    visit application_change_provider_providers_path(application.ecf_id)

    choose(another_provider.name, visible: :all)

    click_button("Continue")

    expect(page).to have_current_path(application_change_provider_check_answers_path(application.ecf_id))

    expect(page).to have_text(another_provider.name)

    #
    # Check answers page
    #
    within("#new-provider") do
      expect(page).to have_text(another_provider.name)
    end

    click_button("Submit change")

    expect(page).to have_current_path(application_path(application.reload.superceding_application.ecf_id))
  end
end
