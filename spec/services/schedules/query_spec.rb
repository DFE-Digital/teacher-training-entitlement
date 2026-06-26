require "rails_helper"

RSpec.describe Schedules::Query do
  subject(:query) do
    described_class.new(
      lead_provider:,
      cohort_start_years:,
      course_identifier:,
      sort:,
    )
  end

  let(:lead_provider) { create(:lead_provider) }
  let(:cohort_start_years) { :ignore }
  let(:course_identifier) { :ignore }
  let(:sort) { nil }

  let(:schedule1) { create(:schedule, cohort: create(:cohort, course: create(:course, identifier: "other"))) }
  let(:schedule2) { create(:schedule, cohort: create(:cohort, start_year: 2021, registration_starts_at: Date.new(2021, 9, 1))) }

  describe "#schedules" do
    before do
      create(:cohort_provider, cohort: schedule1.cohort, lead_provider:)
      create(:cohort_provider, cohort: schedule2.cohort, lead_provider:)
    end

    it "returns all schedules" do
      expect(query.schedules).to include(schedule1, schedule2)
    end

    context "with cohort filter" do
      let(:cohort_start_years) { "2021" }

      it { expect(query.schedules).to include(schedule2) }
    end

    context "with course filter" do
      let(:course_identifier) { "other" }

      it { expect(query.schedules).to include(schedule1) }
    end

    context "when empty result set" do
      let(:course_identifier) { "unknown" }

      it { expect(query.schedules).to be_empty }
    end
  end
end
