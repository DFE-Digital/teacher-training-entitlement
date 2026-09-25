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
    subject(:course_cohort) { build(:course_cohort, cohort:, academic_year:) }

    let(:cohort) { build(:cohort, registration_starts_at: Date.new(2027, 9, 1)) }
    let(:academic_year) { 2027 }

    it { is_expected.to validate_uniqueness_of(:ecf_id).case_insensitive }
    it { is_expected.to validate_numericality_of(:academic_year).only_integer.is_greater_than_or_equal_to(0).allow_nil }

    it "allows academic year to match a September registration start year" do
      expect(course_cohort).to be_valid
    end

    context "when registration starts before September" do
      let(:cohort) { build(:cohort, registration_starts_at: Date.new(2028, 3, 1), start_year: 2028) }
      let(:academic_year) { 2028 }

      it "allows academic year to match the cohort start year" do
        expect(course_cohort).to be_valid
      end
    end

    context "when academic year is blank" do
      let(:cohort) { build(:cohort, registration_starts_at: Date.new(2028, 3, 1)) }
      let(:academic_year) { nil }

      it "allows academic year to be blank" do
        expect(course_cohort).to be_valid
      end
    end

    context "when academic year does not match the cohort start year" do
      let(:cohort) { build(:cohort, registration_starts_at: Date.new(2028, 3, 1), start_year: 2027) }
      let(:academic_year) { 2028 }

      it "is invalid" do
        expect(course_cohort).to have_error(:academic_year, "must be 2027 for the cohort registration start date")
      end
    end
  end

  describe "#contract" do
    subject(:course_cohort) { course_cohort_provider.course_cohort }

    let(:course_cohort_provider) { create(:course_cohort_provider) }
    let(:lead_provider) { course_cohort_provider.lead_provider }

    it { expect(course_cohort.contract(lead_provider:)).to eq(course_cohort_provider) }
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

  describe "defaults" do
    let(:course_cohort) do
      create(
        :course_cohort,
        cohort: create(:cohort, registration_starts_at: Date.new(2028, 3, 1)),
        academic_year: nil,
        term_identifier: nil,
      )
    end

    it "sets the academic year from the cohort start year on create" do
      expect(course_cohort.academic_year).to eq(2028)
    end

    it "sets the term identifier from the cohort registration start date on create" do
      expect(course_cohort.term_identifier).to eq("spring")
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
