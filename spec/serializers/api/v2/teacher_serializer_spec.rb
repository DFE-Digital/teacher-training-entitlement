require "rails_helper"

RSpec.describe API::V2::TeacherSerializer do
  describe ".identifier" do
    let(:user) { build(:user, trn: nil, ecf_id: SecureRandom.uuid) }

    it "uses the ecf_id without a TRN" do
      expect(described_class.identifier(user)).to eq(user.ecf_id)
    end

    it "uses the TRN string with leading zeroes once assigned" do
      user.trn = "0012345"

      expect(described_class.identifier(user)).to eq("0012345")
    end
  end
end
