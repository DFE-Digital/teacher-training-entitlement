require "rails_helper"

RSpec.describe SessionWizardSteps::SignIn, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:email) }
  end

  describe "#after_save" do
    subject { described_class.new(email:, wizard:).after_save }

    before do
      freeze_time
      allow(OTP).to receive(:generate).and_return(otp)
    end

    let(:session) { {} }
    let(:store) { {} }
    let(:admin) { create(:admin) }
    let(:email) { admin.email }
    let(:request) { ActionController::TestRequest.new({}, session, ApplicationController) }
    let(:wizard) { SessionWizard.new(current_step: :sign_in, store:, session:) }
    let(:otp) { OTP.new(code: "ABCD2345", expires_at: 10.minutes.from_now) }

    it "generates an OTP code" do
      expect { subject }.to change { AdminUser.find(admin.id).otp_hash }.from(nil).to("ABCD2345")
    end

    it "sets the OTP expiration time" do
      expect { subject }.to change { AdminUser.find(admin.id).otp_expires_at }.from(nil).to(10.minutes.from_now)
    end

    it "sends an email with the OTP code" do
      expect(GenericMailer).to receive(:with).with(to: email, code: "ABCD2345").and_call_original
      subject
    end

    it "catches Notify errors" do
      message = instance_double(ActionMailer::MessageDelivery)
      allow(GenericMailer).to receive(:with).and_return(instance_double(GenericMailer, confirmation_code: message))
      allow(message).to receive(:deliver_now)
        .and_raise(Notifications::Client::BadRequestError.new(instance_double(Net::HTTPResponse, code: 400, body: "error")))

      expect { subject }.not_to raise_error
    end
  end
end
