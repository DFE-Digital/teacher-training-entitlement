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
    it { is_expected.to have_many(:milestones).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_uniqueness_of(:ecf_id).case_insensitive }
    it { is_expected.to validate_numericality_of(:academic_year).only_integer.is_greater_than_or_equal_to(0).allow_nil }
  end

  describe ".next_open_for" do
    subject(:next_open_course_cohort) { described_class.next_open_for(course:) }

    let(:course) do
      Course.create!(
        name: "Course with cohorts",
        identifier: "course-with-cohorts",
        course_group: "reception",
      )
    end

    around do |example|
      travel_to(Date.new(2029, 6, 1)) { example.run }
    end

    it "returns the earliest course cohort with open registration" do
      later = create(
        :course_cohort,
        course:,
        cohort: create_cohort(Date.new(2029, 5, 1), registration_ends_at: Date.new(2029, 8, 1)),
      )
      earlier = create(
        :course_cohort,
        course:,
        cohort: create_cohort(Date.new(2029, 4, 1), registration_ends_at: Date.new(2029, 8, 1)),
      )

      expect(next_open_course_cohort).to eq(earlier)
      expect(next_open_course_cohort).not_to eq(later)
    end

    it "returns the earliest upcoming course cohort when registration is not open" do
      later = create(
        :course_cohort,
        course:,
        cohort: create_cohort(Date.new(2029, 8, 1)),
      )
      earlier = create(
        :course_cohort,
        course:,
        cohort: create_cohort(Date.new(2029, 7, 1)),
      )

      expect(next_open_course_cohort).to eq(earlier)
      expect(next_open_course_cohort).not_to eq(later)
    end

    def create_cohort(registration_starts_at, registration_ends_at: registration_starts_at.advance(months: 2))
      create(
        :cohort,
        registration_starts_at:,
        registration_ends_at:,
        funding_cap: true,
        description: registration_starts_at.strftime("%B %Y"),
      )
    end
  end

  describe "#application_started_confirmed_by_date" do
    subject(:confirmed_by_date) { course_cohort.application_started_confirmed_by_date }

    let(:course_cohort) do
      create(:course_cohort, schedule: create(:schedule, training_ends_at:, change_training_dates: false))
    end

    context "when training ends between January and April" do
      let(:training_ends_at) { Date.new(2026, 4, 30) }

      it { is_expected.to eq("Spring 2026") }
    end

    context "when training ends after April" do
      let(:training_ends_at) { Date.new(2026, 8, 1) }

      it { is_expected.to eq("Summer 2026") }
    end
  end

  describe "#taken_declaration_types" do
    subject(:taken_declaration_types) { course_cohort.taken_declaration_types(except:) }

    let(:course_cohort) { create(:course_cohort) }
    let(:except) { nil }

    before do
      create(:milestone, course_cohort:, declaration_type: "started")
      create(:milestone, course_cohort:, declaration_type: "completed")
    end

    it "returns the declaration types already used by milestones on the course cohort" do
      expect(taken_declaration_types).to contain_exactly("started", "completed")
    end

    context "when excluding a milestone" do
      let(:except) { course_cohort.milestones.find_by(declaration_type: "started") }

      it "does not include the excluded milestone's declaration type" do
        expect(taken_declaration_types).to contain_exactly("completed")
      end
    end
  end
end
