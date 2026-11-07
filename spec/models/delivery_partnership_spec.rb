require "rails_helper"

RSpec.describe DeliveryPartnership, type: :model do
  describe "relationships" do
    it { is_expected.to belong_to :delivery_partner }
    it { is_expected.to belong_to :lead_provider }
    it { is_expected.to belong_to :course }
    it { is_expected.to have_many(:course_cohorts).through(:course) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of :delivery_partner_id }
    it { is_expected.to validate_presence_of :lead_provider_id }
    it { is_expected.to validate_presence_of :course_id }

    it "does not require the lead provider to deliver the course (no course cohort provider needed)" do
      expect(create(:delivery_partnership)).to be_persisted
    end

    describe "uniqueness" do
      subject { described_class.new }

      before { create :delivery_partnership }

      it "delivery partner must be unique for a given lead provider and course" do
        expect(subject).to validate_uniqueness_of(:delivery_partner_id).scoped_to(%i[lead_provider_id course_id])
      end
    end
  end
end
