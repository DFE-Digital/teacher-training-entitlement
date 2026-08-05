require "rails_helper"

RSpec.describe ContractYear, type: :model do
  subject(:contract_year) { build(:contract_year) }

  describe "paper_trail" do
    it "enables paper trail" do
      expect(described_class.new).to be_versioned
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:lead_provider) }
    it { is_expected.to belong_to(:course) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:lead_provider) }
    it { is_expected.to validate_presence_of(:course) }
    it { is_expected.to validate_uniqueness_of(:lead_provider).scoped_to(%i[course_id academic_year]) }
    it { is_expected.to validate_numericality_of(:academic_year).only_integer.is_greater_than_or_equal_to(0).allow_nil }
    it { is_expected.to validate_numericality_of(:recruitment_target).only_integer.is_greater_than_or_equal_to(0).allow_nil }
    it { is_expected.to validate_numericality_of(:service_fee).is_greater_than_or_equal_to(0).allow_nil }
    it { is_expected.to validate_numericality_of(:teacher_funding).is_greater_than_or_equal_to(0).allow_nil }
  end
end
