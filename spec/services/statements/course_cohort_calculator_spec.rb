require "rails_helper"

RSpec.describe Statements::CourseCohortCalculator do
  let(:cohort) { create(:cohort, :with_funding_cap) }
  let(:lead_provider) { create(:lead_provider) }
  let(:statement) { create(:statement, lead_provider:) }
  let(:course) { create(:course, :npd_eirt) }
  let(:course_cohort) { create(:course_cohort, course:, cohort:) }

  subject { described_class.new(statement:, course_cohort:) }

  before do
    create(:schedule, :tte_reception_autumn, cohort:)
    create(:schedule, :tte_reception_spring, cohort:)
  end

  describe "#funded_rows" do
    it "returns rows for each milestone plus total" do
      app = create(:application, :accepted, :with_funded_place, course_cohort:, lead_provider:)
      create(:declaration, :eligible, declaration_type: "started", application: app, statement:, lead_provider:, value: 60)

      rows = subject.funded_rows

      expect(rows.first).to eq(["Started", 1, 60, 60])
      expect(rows.last).to eq(["Total", 1, nil, 60])
    end

    it "groups by milestone and sums correctly" do
      2.times do
        app = create(:application, :accepted, :with_funded_place, course_cohort:, lead_provider:)
        create(:declaration, :eligible, declaration_type: "started", application: app, statement:, lead_provider:, value: 60)
      end

      rows = subject.funded_rows
      started_row = rows.find { |r| r[0] == "Started" }

      expect(started_row).to eq(["Started", 2, 60, 120])
    end
  end

  describe "#self_funded_rows" do
    it "returns rows for each milestone plus total" do
      app = create(:application, :accepted, :without_funded_place, course_cohort:, lead_provider:)
      create(:declaration, :eligible, declaration_type: "started", application: app, statement:, lead_provider:)

      rows = subject.self_funded_rows

      expect(rows.first).to eq(["Started", 1])
      expect(rows.last).to eq(["Total", 1])
    end
  end
end
