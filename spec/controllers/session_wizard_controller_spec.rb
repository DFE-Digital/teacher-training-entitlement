require "rails_helper"

RSpec.describe SessionWizardController do
  describe "show" do
    context "with valid step" do
      before { get :show, params: { step: "sign-in" } }

      it "renders the page" do
        expect(response).to have_http_status :success
      end
    end

    context "with invalid step" do
      it "raises InvalidStep exception" do
        expect {
          get :show, params: { step: "login" }
        }.to raise_exception SessionWizard::InvalidStep
      end
    end
  end

  describe "#update" do
    context "when signing in successfully" do
      let(:admin) { FactoryBot.create(:admin, otp_hash: "ABCD2345", otp_expires_at: 10.minutes.from_now) }

      it "sets admin_id in session" do
        session["session_store"] = { "email" => admin.email }
        patch :update, params: { step: "sign-in-code", session_wizard: { code: "ABCD2345" } }
        expect(session["admin_id"]).to be_present
      end

      it "changes the session to prevent fixation attack" do
        allow(controller).to receive(:reset_session)

        session["session_store"] = { "email" => admin.email }
        patch :update, params: { step: "sign-in-code", session_wizard: { code: "ABCD2345" } }

        expect(controller).to have_received(:reset_session)
      end
    end

    context "when the code has been used" do
      let(:admin) { FactoryBot.create(:admin, otp_hash: "ABCD2345", otp_expires_at: 10.minutes.from_now) }

      before do
        session["session_store"] = { "email" => admin.email }
        patch :update, params: { step: "sign-in-code", session_wizard: { code: "ABCD2345" } }
      end

      it "clears the stored code and expiry" do
        expect(admin.reload.attributes.values_at("otp_hash", "otp_expires_at")).to eq([nil, nil])
      end

      it "rejects reuse of the code" do
        session.delete("admin_id")
        session["session_store"] = { "email" => admin.email }
        patch :update, params: { step: "sign-in-code", session_wizard: { code: "ABCD2345" } }
        expect(session["admin_id"]).to be_nil
      end
    end

    context "when an incorrect code is submitted" do
      let(:admin) { FactoryBot.create(:admin, otp_hash: "ABCD2345", otp_expires_at: 10.minutes.from_now) }

      before do
        session["session_store"] = { "email" => admin.email }
        patch :update, params: { step: "sign-in-code", session_wizard: { code: "WXYZ6789" } }
      end

      it "does not sign in" do
        expect(session["admin_id"]).to be_nil
      end

      it "keeps the valid code" do
        expect(admin.reload.otp_hash).to eq("ABCD2345")
      end
    end

    context "with invalid step" do
      it "raises InvalidStep exception" do
        expect {
          patch :update, params: { step: "login" }
        }.to raise_exception SessionWizard::InvalidStep
      end
    end
  end
end
