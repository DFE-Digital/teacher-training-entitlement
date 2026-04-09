require "rails_helper"

RSpec.describe "Applications::ChangeProvider::CheckAnswers", type: :request do
  let(:application) { create(:application) }
  let(:provider_before_changed) { application.lead_provider }
  let(:new_provider) { create(:lead_provider) }
  let(:user) { application.user }
  let(:url) { "/applications/#{application.ecf_id}/change-provider/check-answers" }
  let(:session) { { user_id: user.id, change_provider: { provider_id: session_provider_id } } }
  let(:session_provider_id) { nil }

  before do
    allow_any_instance_of(ApplicationController)
      .to receive(:session)
      .and_return(session)

    create(:course_cohort, lead_provider: new_provider,
                           course: application.course,
                           cohort: application.cohort)
  end

  describe "GET /applications/:application_id/change-provider/check-answers" do
    context "with valid provider_id in the session" do
      let(:session_provider_id) { new_provider.id }

      it "renders the index template" do
        get url
        expect(response).to render_template(:index)
      end
    end

    context "with missing provider_id in the session" do
      let(:session_provider_id) { nil }

      it "redirects back to the start page" do
        get url
        expect(response).to redirect_to(application_change_provider_start_index_path(application.ecf_id))
      end
    end
  end

  describe "POST /applications/:application_id/change-provider/check-answers" do
    context "with valid provider_id in the session" do
      let(:session_provider_id) { new_provider.id }

      context "when creating new application fails" do
        it "redirects to the check answers page with a flash message" do
          mocked_service = instance_double(Applications::ChangeLeadProvider, call: nil, errors: ActiveModel::Errors.new(:self).tap { |e| e.add(:base, "bang") })
          allow(Applications::ChangeLeadProvider).to receive(:new).and_return(mocked_service)

          post url
          aggregate_failures do
            last_application = user.applications.reload.last
            expect(last_application).not_to be(application)

            expect(response).to redirect_to(application_change_provider_check_answers_path(application.ecf_id))

            expect(flash[:alert][:title]).to eq(I18n.t("applications.change_provider.check_answers.fail.title"))
            expect(flash[:alert][:message]).to eq("bang")
          end
        end
      end

      context "when creating new application succeeds" do
        it "creates a new application and redirects to user registrations path" do
          post url
          aggregate_failures do
            new_application = user.applications.max_by(&:id)
            expect(new_application).not_to be(application)

            expect(application.reload.superceding_application).to eq(new_application)

            expect(response).to redirect_to(application_path(new_application.ecf_id))
            # Check the new application has got the new provider and the old one has not changed
            expect(new_application.lead_provider_id).to eq(new_provider.id)
            expect(application.reload.lead_provider_id).to eq(provider_before_changed.id)

            expect(flash[:notice][:title]).to eq(I18n.t("applications.change_provider.check_answers.success.title"))
            expect(flash[:notice][:message]).to eq(I18n.t("applications.change_provider.check_answers.success.message"))
          end
        end
      end
    end

    context "with missing provider_id in the session" do
      let(:session_provider_id) { nil }

      it "redirects back to the start page" do
        post url
        expect(response).to redirect_to(application_change_provider_start_index_path(application.ecf_id))
      end
    end
  end
end
