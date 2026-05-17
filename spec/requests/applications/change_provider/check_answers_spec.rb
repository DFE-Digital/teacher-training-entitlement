require "rails_helper"

RSpec.describe "Applications::ChangeProvider::CheckAnswers", type: :request do
  let(:application) { create(:application) }
  let(:provider_before_changed) { application.lead_provider }
  let(:new_provider) { create(:lead_provider) }
  let(:user) { application.user }
  let(:url) { "/applications/#{application.ecf_id}/change-provider/check-answers" }
  let(:change_provider_session_key) { "change_provider_#{application.ecf_id}" }
  let(:session) { { user_id: user.id, change_provider_session_key => { provider_id: session_provider_id } }.with_indifferent_access }
  let(:session_provider_id) { nil }

  before do
    allow_any_instance_of(ApplicationController)
      .to receive(:session)
      .and_return(session)

    create(:course_cohort, lead_provider: new_provider,
                           course: application.course,
                           cohort: application.cohort)
  end

  describe "GET /applications/:application_ecf_id/change-provider/check-answers" do
    context "with valid provider_id in the session" do
      let(:session_provider_id) { new_provider.id }

      it "renders the index template" do
        get url
        expect(response).to render_template(:show)
        expect(response).to render_template(:_check_answers)
      end
    end

    context "with missing provider_id in the session" do
      let(:session_provider_id) { nil }

      it "redirects back to the start page" do
        get url
        expect(response).to redirect_to(application_change_provider_path(application.ecf_id, "start"))
      end
    end

    context "with provider_id for another application in the session" do
      let(:other_application) { create(:application, user:) }
      let(:session) { { user_id: user.id, "change_provider_#{other_application.ecf_id}" => { provider_id: new_provider.id } }.with_indifferent_access }

      it "redirects back to the start page" do
        get url
        expect(response).to redirect_to(application_change_provider_path(application.ecf_id, "start"))
      end
    end

    context "with unavailable provider_id in the session" do
      let(:unavailable_provider) { create(:lead_provider) }
      let(:session_provider_id) { unavailable_provider.id }

      it "redirects back to the start page" do
        get url
        expect(response).to redirect_to(application_change_provider_path(application.ecf_id, "start"))
      end
    end

    context "when application is not eligible for change provider" do
      let(:application) { create(:application, :started) }

      it "redirects to the application page" do
        get url
        expect(response).to redirect_to(application_path(application.ecf_id))
      end
    end
  end

  describe "PATCH /applications/:application_ecf_id/change-provider/check-answers" do
    context "with valid provider_id in the session" do
      let(:session_provider_id) { new_provider.id }

      context "when changing provider fails" do
        it "redirects to the check answers page with a flash message" do
          mocked_service = instance_double(Applications::ChangeLeadProvider, call: nil, errors: ActiveModel::Errors.new(:self).tap { |e| e.add(:base, "bang") })
          allow(Applications::ChangeLeadProvider).to receive(:new).and_return(mocked_service)

          patch url
          aggregate_failures do
            last_application = user.applications.reload.last
            expect(last_application).not_to be(application)

            expect(response).to redirect_to(application_change_provider_path(application.ecf_id, "exit"))

            expect(flash[:alert]).not_to be_nil
            expect(flash[:alert][:title]).to eq(I18n.t("applications.change_provider.check_answers.fail.title"))
            expect(flash[:alert][:message]).to eq("bang")
          end
        end
      end

      context "when changing provider succeeds" do
        it "creates updates the application provider and redirects to user registrations path" do
          allow(GenericMailer).to receive(:with).and_call_original

          expect(GenericMailer).to receive(:with).with(
            to: application.user.email,
            full_name: application.user.full_name,
            provider_name: new_provider.name,
            course_name: application.course.name,
            cohort_date: application.cohort.name,
            ecf_id: application.ecf_id,
            sign_in_link: Rails.configuration.sign_in_link,
            feedback_link: Rails.configuration.feedback_link,
          ).and_call_original

          patch url

          aggregate_failures do
            expect(response).to redirect_to(application_change_provider_path(application.ecf_id, "exit"))
            expect(application.reload.lead_provider.id).to eq(new_provider.id)

            expect(flash[:success]).not_to be_nil
            expect(flash[:success][:title]).to eq(I18n.t("applications.change_provider.check_answers.success.title"))
            expect(flash[:success][:message]).to eq(I18n.t("applications.change_provider.check_answers.success.message"))
          end
        end
      end
    end

    context "with missing provider_id in the session" do
      let(:session_provider_id) { nil }

      it "redirects back to the exit" do
        patch url
        expect(assigns[:step].errors[:base]).to eq([I18n.t("applications.change_provider.providers.form.invalid")])
      end
    end
  end
end
