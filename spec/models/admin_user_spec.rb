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

  describe "#otp" do
    subject(:otp) { admin.otp }

    let(:admin) { build(:admin, otp_hash:, otp_expires_at:) }
    let(:otp_hash) { "ABCD2345" }
    let(:otp_expires_at) { 10.minutes.from_now }

    it { is_expected.to be_a(OTP) }
    it { expect(otp.code).to eq("ABCD2345") }

    context "when the code is missing" do
      let(:otp_hash) { nil }

      it { is_expected.to be_nil }
    end

    context "when the code is a legacy six digit code" do
      let(:otp_hash) { "123456" }

      it { is_expected.to be_nil }
    end

    context "when the expiry is missing" do
      let(:otp_expires_at) { nil }

      it { is_expected.to be_nil }
    end
  end

  describe "#clear_otp!" do
    let(:admin) { create(:admin, otp_hash: "ABCD2345", otp_expires_at: 10.minutes.from_now) }

    it "clears the code and expiry" do
      admin.clear_otp!
      expect(admin.reload.attributes.values_at("otp_hash", "otp_expires_at")).to eq([nil, nil])
    end
  end

  describe "#email downcase" do
    subject(:email) { user.email }

    let(:user) { build(:admin, email: "SOME@EDUCATION.GOV.UK") }

    before { user.save! }

    it { is_expected.to eq("some@education.gov.uk") }
  end
end
