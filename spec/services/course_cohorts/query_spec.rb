require "rails_helper"

RSpec.describe CourseCohorts::Query do
  subject(:query) do
    described_class.new(
      lead_provider:,
      academic_years:,
      course_identifier:,
      sort:,
    )
  end

  let(:lead_provider) { create(:lead_provider) }
  let(:academic_years) { :ignore }
  let(:course_identifier) { :ignore }
  let(:sort) { nil }

  let(:course_cohort1) { create(:course_cohort, course: create(:course, identifier: "other")) }
  let(:course_cohort2) { create(:course_cohort, academic_year: 2021) }

  describe "#course_cohorts" do
    before do
      create(:course_cohort_provider, course_cohort: course_cohort1, lead_provider:)
      create(:course_cohort_provider, course_cohort: course_cohort2, lead_provider:)
    end

    it "returns all course_cohorts" do
      expect(query.course_cohorts).to include(course_cohort1, course_cohort2)
    end

    context "with cohort filter" do
      let(:academic_years) { "2021" }

      it { expect(query.course_cohorts).to include(course_cohort2) }
    end

    context "with course filter" do
      let(:course_identifier) { "other" }

      it { expect(query.course_cohorts).to include(course_cohort1) }
    end

    context "when empty result set" do
      let(:course_identifier) { "unknown" }

      it { expect(query.course_cohorts).to be_empty }
    end
  end
end
