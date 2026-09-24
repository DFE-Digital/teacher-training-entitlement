require "rails_helper"

RSpec.describe CourseCohort do
  subject(:course_cohort) { create(:course_cohort) }

  describe "relationships" do
    it { is_expected.to belong_to(:course) }
    it { is_expected.to belong_to(:cohort) }
    it { is_expected.to have_many(:course_cohort_providers).dependent(:destroy) }
    it { is_expected.to have_many(:lead_providers).through(:course_cohort_providers) }
    it { is_expected.to have_many(:delivery_partnerships).dependent(:destroy) }
    it { is_expected.to have_many(:delivery_partners).through(:delivery_partnerships) }
    it { is_expected.to have_many(:milestones).through(:course) }
    it { is_expected.to have_one(:started_milestone).through(:course).source(:milestones) }
    it { is_expected.to have_one(:completed_milestone).through(:course).source(:milestones) }
  end

  describe "validations" do
    it { is_expected.to validate_uniqueness_of(:ecf_id).case_insensitive }
    it { is_expected.to validate_numericality_of(:academic_year).only_integer.is_greater_than_or_equal_to(0).allow_nil }
  end

  describe "#taken_declaration_types" do
    subject(:taken_declaration_types) { course_cohort.taken_declaration_types(except:) }

    let(:course_cohort) { create(:course_cohort) }
    let(:except) { nil }

    it "returns the declaration types already used by milestones on the course cohort" do
      expect(taken_declaration_types).to contain_exactly("started", "completed")
    end

    context "when excluding a milestone" do
      let(:except) { course_milestone(course_cohort.course, :started) }

      it "does not include the excluded milestone's declaration type" do
        expect(taken_declaration_types).to contain_exactly("completed")
      end
    end
  end

  describe "schedule_identifier" do
    subject(:schedule_identifier) { build(:course_cohort, course:, term_identifier: :autumn).schedule_identifier }

    context "when course is tte-early-years" do
      let(:course) { build(:course, identifier: Course::TTE_EARLY_YEARS) }

      it { is_expected.to eq("tte-reception-autumn") }
    end

    context "when course not tte-early-years" do
      let(:course) { build(:course, identifier: "npd-teachers") }

      it { is_expected.to eq("npd-teachers-autumn") }
    end
  end

  describe "term_identifier" do
    subject(:term_identifier) { described_class.school_term(start_date) }

    context "with start_date between sept and dec" do
      [9, 10, 11, 12].each do |month|
        let(:start_date) { Date.new(2026, month, 1) }

        it { is_expected.to eq(:autumn) }
      end
    end

    context "with start_date between jan and apr" do
      [1, 2, 3, 4].each do |month|
        let(:start_date) { Date.new(2026, month, 1) }

        it { is_expected.to eq(:spring) }
      end
    end

    context "with start_date between may and aug" do
      [5, 6, 7, 8].each do |month|
        let(:start_date) { Date.new(2026, month, 1) }

        it { is_expected.to eq(:summer) }
      end
    end
  end
end
