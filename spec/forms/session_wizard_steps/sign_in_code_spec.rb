require "rails_helper"

RSpec.describe SessionWizardSteps::SignInCode, type: :model do
  subject do
    described_class.new(code:)
  end

  let(:admin) { FactoryBot.create(:admin, email: "test@example.com") }
  let(:code) { nil }
  let(:store) { { "email" => admin.email } }
  let(:session) { {} }
  let(:wizard) do
    SessionWizard.new(store:,
                      current_step: "sign_in_code",
                      session:)
  end

  before do
    subject.wizard = wizard
  end

  describe "validations" do
    context "when non existent user" do
      let(:store) { { "email" => "noexist@example.com" } }

      it { is_expected.to validate_presence_of(:code) }
    end

    it { is_expected.to validate_length_of(:code).is_equal_to(6) }

    context "when correct code given" do
      let(:admin) { FactoryBot.create(:admin, otp_hash: "123456", otp_expires_at: 10.minutes.from_now) }
      let(:code) { "123456" }

      it "passes" do
        expect(subject).to be_valid
      end
    end

    context "when code expired" do
      let(:admin) { FactoryBot.create(:admin, otp_hash: "123456", otp_expires_at: 1.minute.ago) }
      let(:code) { "123456" }

      it "fails" do
        subject.valid?
        expect(subject.errors).to be_of_kind(:code, :expired)
      end
    end

    context "when incorrect code given" do
      let(:admin) { FactoryBot.create(:admin, otp_hash: "222222", otp_expires_at: 10.minutes.from_now) }
      let(:code) { "111111" }

      it "fails" do
        subject.valid?

        expect(subject.errors).to be_of_kind(:code, :incorrect)
      end

      it "increments failed attempts" do
        expect { subject.valid? }.to change { admin.reload.otp_failed_attempts }.by(1)
      end
    end

    context "when account is locked out" do
      let(:admin) { FactoryBot.create(:admin, otp_hash: "123456", otp_expires_at: 10.minutes.from_now, otp_failed_attempts: OtpAuthenticatable::MAX_OTP_ATTEMPTS) }
      let(:code) { "123456" }

      it "fails with locked error even with correct code" do
        subject.valid?

        expect(subject.errors).to be_of_kind(:code, :locked)
      end
    end

    context "when account becomes locked after failed attempt" do
      let(:admin) { FactoryBot.create(:admin, otp_hash: "123456", otp_expires_at: 10.minutes.from_now, otp_failed_attempts: OtpAuthenticatable::MAX_OTP_ATTEMPTS - 1) }
      let(:code) { "000000" }

      it "clears the OTP when locked" do
        subject.valid?
        admin.reload

        expect(admin.otp_hash).to be_nil
        expect(admin.otp_expires_at).to be_nil
      end
    end
  end
end
