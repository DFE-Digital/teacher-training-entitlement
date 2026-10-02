require "rails_helper"

RSpec.describe Admin::Applications::RevertToPendingForm, type: :model do
  subject(:form) { described_class.new(application:, change_status_to_pending:) }

  let(:application) { create(:application, :accepted) }
  let(:change_status_to_pending) { "yes" }

  describe "validations" do
    it { is_expected.to allow_value("yes").for(:change_status_to_pending) }
    it { is_expected.not_to allow_value("no").for(:change_status_to_pending) }
    it { is_expected.not_to allow_value(nil).for(:change_status_to_pending) }
  end

  describe "#application" do
    it "returns the application" do
      expect(form.application).to eq(application)
    end
  end
end
