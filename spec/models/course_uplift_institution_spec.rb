require "rails_helper"

RSpec.describe CourseUpliftInstitution, type: :model do
  subject { build(:course_uplift_institution) }

  describe "paper_trail" do
    it "enables paper trail" do
      expect(described_class.new).to be_versioned
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:course) }
    it { is_expected.to belong_to(:institution) }
  end

  describe "validations" do
    it { is_expected.to validate_uniqueness_of(:institution_id).scoped_to(:course_id) }
  end
end
