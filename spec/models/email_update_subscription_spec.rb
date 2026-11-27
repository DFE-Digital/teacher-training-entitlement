require "rails_helper"

RSpec.describe EmailUpdateSubscription do
  subject(:subscription) { build(:email_update_subscription) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_uniqueness_of(:email).scoped_to(:status).ignoring_case_sensitivity }
    it { is_expected.not_to allow_value("not-an-email").for(:email) }
  end

  describe "enums" do
    it {
      expect(subscription).to define_enum_for(:status).with_values(
        npd_registration_open: "npd_registration_open",
      ).backed_by_column_of_type(:enum).with_suffix
    }
  end

  describe "#unsubscribe_key" do
    it "is generated for each subscription" do
      expect(subscription.unsubscribe_key).to be_present
      expect(subscription.unsubscribe_key).not_to eq(build(:email_update_subscription).unsubscribe_key)
    end
  end
end
