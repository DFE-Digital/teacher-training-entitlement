require "rails_helper"

RSpec.describe "Registration wizard parity / Course Start Date", type: :request do
  let(:application) { create(:application, :pending) }
  let(:user) { application.user }
  let(:session) { { user_id: user.id }.with_indifferent_access }
  let(:application_course_start_date) { "autumn 2025" }

  let(:expected_content) do
    [
      I18n.t("helpers.title.registration_wizard.course_start_date", date: application_course_start_date),
      I18n.t("helpers.hint.registration_wizard.course_start_date_one"),
      I18n.t("helpers.hint.registration_wizard.course_start_date_two"),
      I18n.t("helpers.hint.registration_wizard.course_start_date_three", date: application_course_start_date),
      "Do you want to start a course in #{application_course_start_date}?",
      I18n.t("helpers.label.registration_wizard.course_start_date_options.yes"),
      I18n.t("helpers.hint.registration_wizard.course_start_date_hint"),
      I18n.t("helpers.label.registration_wizard.course_start_date_options.no"),
    ]
  end

  let(:wizards) do
    {
      old: {
        url: "/registration/course-start-date",
        yes_params: { registration_wizard: { course_start_date: "yes" } },
        no_params: { registration_wizard: { course_start_date: "no" } },
        invalid_params: { registration_wizard: { course_start_date: nil } },
        choose_course_path: "/registration/choose-your-course",
        cannot_register_yet_path: "/registration/cannot-register-yet",
      },
      new: {
        url: "/reception-registration/course-start-date",
        yes_params: { "course-start-date" => { confirmation: "yes" } },
        no_params: { "course-start-date" => { confirmation: "no" } },
        invalid_params: { "course-start-date" => { confirmation: nil } },
        choose_course_path: "/reception-registration/choose-your-course",
        cannot_register_yet_path: "/reception-registration/cannot-register-yet",
      },
    }
  end

  before do
    allow_any_instance_of(ApplicationController)
      .to receive(:session)
      .and_return(session)
  end

  it "renders the same visible content" do
    wizards.each_value do |wizard|
      get wizard[:url]

      expect(response).to have_http_status(:ok)
      expected_content.each do |text|
        expect(response.body).to include(CGI.escapeHTML(text))
      end
    end
  end

  it "redirects to choose your course when the user confirms the course start date" do
    wizards.each_value do |wizard|
      patch wizard[:url], params: wizard[:yes_params]

      expect(response).to redirect_to(wizard[:choose_course_path])
    end
  end

  it "redirects to cannot register yet when the user rejects the course start date" do
    wizards.each_value do |wizard|
      patch wizard[:url], params: wizard[:no_params]

      expect(response).to redirect_to(wizard[:cannot_register_yet_path])
    end
  end

  it "renders the form again when the user does not answer" do
    wizards.each_value do |wizard|
      patch wizard[:url], params: wizard[:invalid_params]

      expect(response).to have_http_status(:ok)
      expected_content.each do |text|
        expect(response.body).to include(CGI.escapeHTML(text))
      end
    end
  end
end
