require "rails_helper"

RSpec.feature "Change provider", type: :feature do
  let(:application) { nil }
  let(:another_provider) { create(:lead_provider) }

  before do
    page.set_rack_session("user_id" => application.user.id)
    create(:course_cohort, lead_provider: another_provider,
                           course: application.course,
                           cohort: application.cohort)
  end

  RSpec.shared_examples "changing provider successfully" do
    it do
      #
      # Start page
      #
      visit application_change_provider_path(application.ecf_id, :start)

      expect(page).to have_text("Register with a different provider for the #{application.course.name}")

      choose(I18n.t("applications.change_provider.start.application_#{application.status}.form.yes_option"), visible: :all)

      click_button("Continue")

      expect(page).to have_current_path(application_change_provider_path(application.ecf_id, :"choose-provider"))

      #
      # Providers page
      #
      choose(another_provider.name, visible: :all)

      click_button("Continue")

      expect(page).to have_current_path(application_change_provider_path(application.ecf_id, :"check-answers"))

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
      visit application_change_provider_path(application.ecf_id, :start)

      expect(page).to have_current_path(application_path(application.ecf_id))
    end
  end

  context "when application is started" do
    let(:application) { create(:application, :started) }

    it "redirects you back to application#show" do
      visit application_change_provider_path(application.ecf_id, :start)

      expect(page).to have_current_path(application_path(application.ecf_id))
    end
  end
end
