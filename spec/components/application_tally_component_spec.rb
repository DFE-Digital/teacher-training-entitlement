require "rails_helper"

RSpec.describe ApplicationTallyComponent, type: :component do
  subject { described_class.new(Application.joins(:course_cohort).where(course_cohorts: { cohort: }), :course) }

  let(:cohort) { create(:cohort, :current) }
  let(:course_cohort1) { create :course_cohort, cohort:, course: course_1 }
  let(:course_cohort2) { create :course_cohort, cohort:, course: course_2 }
  let(:course_1) { create :course, name: "Course 1" }
  let(:course_2) { create :course, name: "Course 2" }

  before do
    create(:application, course_cohort: course_cohort1)
    create(:application, course_cohort: course_cohort1)
    create(:application, course_cohort: course_cohort2)
  end

  it "returns the correct dimension haeder" do
    expect(subject.dimension_header).to eq("Course")
  end

  it "returns the correct rows" do
    expect(subject.rows).to eq([
      [course_1.name, 2],
      [course_2.name, 1],
    ])
  end

  context "when the dimension has a different label" do
    subject { described_class.new(Application.joins(:course_cohort).where(course_cohorts: { cohort: }), :lead_provider, dimension_header: "Course provider") }

    it "returns the correct dimension header" do
      expect(subject.dimension_header).to eq("Course provider")
    end
  end
end
