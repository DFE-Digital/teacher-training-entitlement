require "rails_helper"

RSpec.feature "Change provider", type: :feature do
  let(:application) { create(:application, :pending) }

  before do
    page.set_rack_session("user_id" => application.user.id)
  end

  it do
    visit application_change_provider_start_index_path(application.ecf_id)

    expect(page).to have_text("Change your provider for the #{application.course.name}")

    choose(I18n.t("applications.change_provider.start.form.yes_option"), visible: :all)

    click_button("Continue")

    expect(page).to have_current_path(application_change_provider_providers_path(application.ecf_id))
  end
end
