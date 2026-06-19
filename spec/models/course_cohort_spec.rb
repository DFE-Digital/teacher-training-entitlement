require "rails_helper"

RSpec.describe CourseCohort do
  subject(:course_cohort) { create(:course_cohort) }

  describe "relationships" do
    it { is_expected.to belong_to(:course) }
    it { is_expected.to belong_to(:cohort) }
    it { is_expected.to belong_to(:schedule) }
    it { is_expected.to have_many(:course_cohort_providers).dependent(:destroy) }
    it { is_expected.to have_many(:lead_providers).through(:course_cohort_providers) }
  end

  describe "validations" do
    it { is_expected.to validate_uniqueness_of(:ecf_id).case_insensitive }
  end

  describe ".next_open_for" do
    subject(:next_open_course_cohort) { described_class.next_open_for(course:) }

    let(:course) do
      build(:course, identifier: "course-with-cohorts").tap(&:save!)
    end

    around do |example|
      travel_to(Date.new(2026, 6, 1)) { example.run }
    end

    it "returns the earliest course cohort with open registration" do
      later = create(
        :course_cohort,
        course:,
        cohort: create(:cohort, start_year: 2026, registration_starts_at: Date.new(2026, 5, 1), registration_ends_at: Date.new(2026, 8, 1)),
      )
      earlier = create(
        :course_cohort,
        course:,
        cohort: create(:cohort, start_year: 2026, registration_starts_at: Date.new(2026, 4, 1), registration_ends_at: Date.new(2026, 8, 1)),
      )

      expect(next_open_course_cohort).to eq(earlier)
      expect(next_open_course_cohort).not_to eq(later)
    end

    it "returns the earliest upcoming course cohort when registration is not open" do
      later = create(
        :course_cohort,
        course:,
        cohort: create(:cohort, start_year: 2026, registration_starts_at: Date.new(2026, 8, 1)),
      )
      earlier = create(
        :course_cohort,
        course:,
        cohort: create(:cohort, start_year: 2026, registration_starts_at: Date.new(2026, 7, 1)),
      )

      expect(next_open_course_cohort).to eq(earlier)
      expect(next_open_course_cohort).not_to eq(later)
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
end
