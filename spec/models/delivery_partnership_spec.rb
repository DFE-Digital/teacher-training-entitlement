require "rails_helper"

RSpec.describe DeliveryPartnership, type: :model do
  describe "relationships" do
    it { is_expected.to belong_to :delivery_partner }
    it { is_expected.to belong_to :lead_provider }
    it { is_expected.to belong_to(:cohort).optional }
    it { is_expected.to belong_to(:course_cohort).optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of :delivery_partner_id }
    it { is_expected.to validate_presence_of :lead_provider_id }

    it "requires either a cohort or course cohort" do
      partnership = build(:delivery_partnership, cohort: nil, course_cohort: nil)

      expect(partnership).not_to be_valid
      expect(partnership.errors).to include(:cohort_id, :course_cohort_id)
    end

    describe "uniqueness" do
      let(:delivery_partner) { create(:delivery_partner) }
      let(:lead_provider) { create(:lead_provider) }

      it "prevents duplicate course cohort partnerships" do
        course_cohort = create(:course_cohort)
        create(:delivery_partnership, delivery_partner:, lead_provider:, course_cohort:, cohort: nil)

        duplicate = build(:delivery_partnership, delivery_partner:, lead_provider:, course_cohort:, cohort: nil)

        expect(duplicate).not_to be_valid
        expect(duplicate.errors.of_kind?(:delivery_partner_id, :taken)).to be true
      end
    end
  end
end
