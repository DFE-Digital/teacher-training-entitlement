require "rails_helper"

RSpec.describe InterestNotificationSignUpController, type: :request do
  describe "#new" do
    context "when registration is closed" do
      before { Flipper.disable(Feature::REGISTRATION_OPEN) }

      it "displays the email sign up form" do
        get registration_interest_sign_up_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include("email")
      end
    end

    context "when registration is open" do
      before { Flipper.enable(Feature::REGISTRATION_OPEN) }

      it "redirects to the service homepage" do
        get registration_interest_sign_up_path

        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "#create" do
    let(:params) do
      { questionnaires_registration_interest_notification: { email: "jane@example.com" } }
    end

    context "when registration is closed" do
      before { Flipper.disable(Feature::REGISTRATION_OPEN) }

      it "redirects to the confirmation page" do
        post registration_interest_sign_up_path, params: params

        expect(response).to redirect_to(registration_interest_sign_up_confirm_path(email: "jane@example.com"))
      end
    end

    context "when registration is open" do
      before { Flipper.enable(Feature::REGISTRATION_OPEN) }

      it "redirects to the service homepage instead of processing the sign up" do
        expect {
          post registration_interest_sign_up_path, params: params
        }.not_to change(RegistrationInterest, :count)

        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "#confirm" do
    context "when registration is closed" do
      before { Flipper.disable(Feature::REGISTRATION_OPEN) }

      it "displays the confirmation page" do
        get registration_interest_sign_up_confirm_path(email: "jane@example.com")

        expect(response).to have_http_status(:success)
      end
    end

    context "when registration is open" do
      before { Flipper.enable(Feature::REGISTRATION_OPEN) }

      it "redirects to the service homepage" do
        get registration_interest_sign_up_confirm_path(email: "jane@example.com")

        expect(response).to redirect_to(root_path)
      end
    end
  end
end
