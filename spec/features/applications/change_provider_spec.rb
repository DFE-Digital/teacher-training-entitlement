require "rails_helper"

RSpec.feature "Change provider", type: :feature do
  let(:application) { nil }
  let(:another_provider) { create(:lead_provider) }

  before do
    page.set_rack_session("user_id" => application.user.id)
    create(:cohort_provider, lead_provider: another_provider,
                             cohort: application.cohort)
  end

  RSpec.shared_examples "changing provider successfully" do
    it do
      #
      # Start page
      #
      visit application_change_provider_start_index_path(application.ecf_id)

      expect(page).to have_text("#{application.course.name} course: register with a different provider")

      choose(I18n.t("applications.change_provider.start.application_#{application.status}.form.yes_option"), visible: :all)

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

      expect(page).to have_current_path(application_path(application.ecf_id))
    end
  end

  context "when application is pending" do
    let(:application) { create(:application, :pending) }

    it_behaves_like "changing provider successfully"
  end

  context "when application is rejected" do
    let(:application) { create(:application, :rejected) }

    it_behaves_like "changing provider successfully"
  end

  context "when application is accepted" do
    let(:application) { create(:application, :accepted) }

    it do
      visit application_change_provider_start_index_path(application.ecf_id)

      expect(page).to have_current_path(application_path(application.ecf_id))
    end
  end

  context "when application is started" do
    let(:application) { create(:application, :started, :for_cohort_starting_on, registration_starts_at: Date.new(2021, 4, 1)) }

    it "redirects you back to application#show" do
      visit application_change_provider_start_index_path(application.ecf_id)

      expect(page).to have_current_path(application_path(application.ecf_id))
    end
  end
end
