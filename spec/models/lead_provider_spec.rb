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

  describe "#delivery_partners_for_cohort" do
    subject { lead_provider.delivery_partners_for_cohort(twenty_three) }

    let :lead_provider do
      create_list(:lead_provider, 2, delivery_partners: {
        twenty_three => twenty_three_partner,
        create(:cohort, registration_starts_at: Date.new(2024, 4, 1)) => twenty_four_partner,
      }).first
    end

    let(:twenty_three) { create(:cohort, registration_starts_at: Date.new(2023, 4, 1)) }
    let(:twenty_three_partner) { create(:delivery_partner) }
    let(:twenty_four_partner) { create(:delivery_partner) }
    let(:unrelated_partner) { create(:delivery_partner) }

    it { is_expected.to have_attributes length: 1 }
    it { is_expected.to include twenty_three_partner }
    it { is_expected.not_to include twenty_four_partner }
    it { is_expected.not_to include unrelated_partner }
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
