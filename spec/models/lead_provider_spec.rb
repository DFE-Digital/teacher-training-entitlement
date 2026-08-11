require "rails_helper"

RSpec.describe LeadProvider do
  describe "relationships" do
    it { is_expected.to have_many(:applications) }
    it { is_expected.to have_many(:statements) }
    it { is_expected.to have_many(:delivery_partnerships) }
    it { is_expected.to have_many(:delivery_partners).through(:delivery_partnerships) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:ecf_id).case_insensitive.with_message("ECF ID must be unique").allow_nil }
  end

  describe "#delivery_partners_for_course_cohort" do
    subject { lead_provider.delivery_partners_for_course_cohort(course_cohort:) }

    let(:lead_provider) do
      create(:lead_provider, delivery_partners: {
        course_cohort => course_cohort_partner,
        other_course_cohort => other_course_cohort_partner,
      })
    end
    let(:course_cohort) { create(:course_cohort) }
    let(:other_course_cohort) { create(:course_cohort, course: create(:course)) }
    let(:course_cohort_partner) { create(:delivery_partner) }
    let(:other_course_cohort_partner) { create(:delivery_partner) }

    it { is_expected.to contain_exactly(course_cohort_partner) }
  end

  describe "#contract" do
    subject(:lead_provider) { create(:lead_provider) }

    let(:course_cohort_one) { create(:course_cohort, course: create(:course), lead_provider:) }
    let(:course_cohort_two) { create(:course_cohort, course: create(:course), lead_provider:) }

    before do
      create(:contract_year, :generic, lead_provider:, course: course_cohort_one.course, recruitment_target: 100)
      create(:contract_year, :generic, lead_provider:, course: course_cohort_two.course, recruitment_target: 200)
    end

    it "returns the contract for each course cohort" do
      expect(lead_provider.contract(course_cohort: course_cohort_one).recruitment_target).to eq(100)
      expect(lead_provider.contract(course_cohort: course_cohort_two).recruitment_target).to eq(200)
    end
  end
end
