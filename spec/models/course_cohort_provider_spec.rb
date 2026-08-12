require "rails_helper"

RSpec.describe CourseCohortProvider do
  subject(:course_cohort_provider) { create(:course_cohort_provider) }

  describe "relationships" do
    it { is_expected.to belong_to(:course_cohort) }
    it { is_expected.to belong_to(:lead_provider) }
  end

  describe "validations" do
    it { is_expected.to validate_numericality_of(:recruitment_target).only_integer.is_greater_than_or_equal_to(0).allow_nil }
    it { is_expected.to validate_numericality_of(:teacher_funding).is_greater_than_or_equal_to(0).allow_nil }
  end

  describe "#contract_year" do
    let(:course) { create(:course) }
    let(:lead_provider) { create(:lead_provider) }
    let(:course_cohort) { create(:course_cohort, course:, lead_provider:, academic_year:) }
    let(:course_cohort_provider) { course_cohort.course_cohort_providers.find_by!(lead_provider:) }

    context "when the course cohort has an academic year" do
      let(:academic_year) { 2026 }

      it "returns the contract year for the matching lead provider, course and academic year" do
        create(:contract_year, :generic, lead_provider:, course:)
        create(:contract_year, :generic, lead_provider:, academic_year:, course: create(:course))
        create(:contract_year, :generic, lead_provider:, course:, academic_year: academic_year - 1)

        matching_contract_year = create(:contract_year, :generic, lead_provider:, course:, academic_year:)

        expect(course_cohort_provider.contract_year).to eq(matching_contract_year)
      end
    end

    context "when the course cohort does not have an academic year" do
      let(:academic_year) { nil }

      it "returns the contract year for the matching lead provider and course" do
        create(:contract_year, :generic, lead_provider:, course: create(:course))

        matching_contract_year = create(:contract_year, :generic, lead_provider:, course:)

        expect(course_cohort_provider.contract_year).to eq(matching_contract_year)
      end
    end
  end
end
