require "rails_helper"

RSpec.describe SessionWizardSteps::SignIn, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:email) }
  end

  describe "#after_save" do
    subject { described_class.new(email:, wizard:).after_save }

    before { freeze_time }

    let(:session) { {} }
    let(:store) { {} }
    let(:admin) { create(:admin) }
    let(:email) { admin.email }
    let(:request) { ActionController::TestRequest.new({}, session, ApplicationController) }
    let(:wizard) { SessionWizard.new(current_step: :sign_in, store:, session:) }

    it "generates a 6-digit OTP code" do
      subject
      expect(admin.reload.otp_hash).to match(/\A\d{6}\z/)
    end

    it "sets the OTP expiration time" do
      expect { subject }.to change { AdminUser.find(admin.id).otp_expires_at }.from(nil).to(10.minutes.from_now)
    end

    it "sends an email with the OTP code" do
      allow(GenericMailer).to receive(:with).and_call_original
      subject
      expect(GenericMailer).to have_received(:with).with(to: email, code: admin.reload.otp_hash)
    end

    it "catches Notify errors" do
      message = instance_double(ActionMailer::MessageDelivery)
      allow(GenericMailer).to receive(:with).and_return(instance_double(GenericMailer, confirmation_code: message))
      allow(message).to receive(:deliver_now)
        .and_raise(Notifications::Client::BadRequestError.new(instance_double(Net::HTTPResponse, code: 400, body: "error")))

      expect { subject }.not_to raise_error
    end

    context "when admin has failed OTP attempts" do
      let(:admin) { create(:admin, otp_failed_attempts: 3) }

      it "resets the OTP failed attempts counter" do
        expect { subject }.to change { admin.reload.otp_failed_attempts }.from(3).to(0)
      end
    end
  end
end
