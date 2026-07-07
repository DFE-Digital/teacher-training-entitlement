require "rails_helper"

RSpec.describe AdminUser, type: :model do
  describe "validation" do
    describe "full_name" do
      it { is_expected.to validate_presence_of(:full_name).with_message("Enter a full name") }
      it { is_expected.to validate_length_of(:full_name).is_at_most(64).with_message("Full name must be shorter than 64 characters") }
    end

    describe "email" do
      it { is_expected.to validate_presence_of(:email).with_message("Enter an email address in the correct format, like name@example.com") }
      it { is_expected.to validate_length_of(:email).is_at_most(64).with_message("Email must be shorter than 64 characters") }
    end
  end

  describe "defaults" do
    specify "super_admin defaults to false" do
      expect(AdminUser.new.super_admin?).to be false
    end
  end

  describe "#name_with_email" do
    subject { admin.name_with_email }

    let(:admin) { build(:admin) }

    it { is_expected.to eq("#{admin.full_name} (#{admin.email})") }
  end

  describe "#otp_locked_out?" do
    let(:admin) { create(:admin, otp_failed_attempts: 0) }

    it "returns false when failed attempts are below the maximum" do
      expect(admin.otp_locked_out?).to be false
    end

    it "returns true when failed attempts reach the maximum" do
      admin.update!(otp_failed_attempts: AdminUser::MAX_OTP_ATTEMPTS)
      expect(admin.otp_locked_out?).to be true
    end
  end

  describe "#increment_otp_failed_attempts!" do
    let(:admin) { create(:admin, otp_hash: "123456", otp_expires_at: 10.minutes.from_now, otp_failed_attempts: 0) }

    it "increments the failed attempts counter" do
      expect { admin.increment_otp_failed_attempts! }.to change { admin.reload.otp_failed_attempts }.by(1)
    end

    it "clears the OTP when lockout is reached" do
      admin.update!(otp_failed_attempts: AdminUser::MAX_OTP_ATTEMPTS - 1)
      admin.increment_otp_failed_attempts!
      admin.reload

      expect(admin.otp_hash).to be_nil
      expect(admin.otp_expires_at).to be_nil
    end
  end

  describe "#clear_otp!" do
    let(:admin) { create(:admin, otp_hash: "123456", otp_expires_at: 10.minutes.from_now) }

    it "clears the OTP hash and expiry" do
      admin.clear_otp!
      admin.reload

      expect(admin.otp_hash).to be_nil
      expect(admin.otp_expires_at).to be_nil
    end
  end
end
