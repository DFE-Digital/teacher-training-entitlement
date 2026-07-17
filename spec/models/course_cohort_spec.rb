require "rails_helper"

RSpec.describe CourseCohort do
  subject(:course_cohort) { create(:course_cohort) }

  describe "relationships" do
    it { is_expected.to belong_to(:course) }
    it { is_expected.to belong_to(:cohort) }
    it { is_expected.to belong_to(:schedule) }
    it { is_expected.to have_many(:course_cohort_providers).dependent(:destroy) }
    it { is_expected.to have_many(:lead_providers).through(:course_cohort_providers) }
    it { is_expected.to have_many(:milestones).dependent(:destroy) }
    it { is_expected.to have_many(:statements).through(:milestones) }
  end

  describe "validations" do
    it { is_expected.to validate_uniqueness_of(:ecf_id).case_insensitive }
    it { is_expected.to validate_numericality_of(:service_fee).is_greater_than_or_equal_to(0).allow_nil }
    it { is_expected.to validate_numericality_of(:participant_funding).is_greater_than_or_equal_to(0).allow_nil }

    it "is invalid when participant_funding is less than sum of milestones" do
      course_cohort = create(:course_cohort, participant_funding: 1000)
      create(:milestone, course_cohort:, payment_amount: 600)

      course_cohort.participant_funding = 500

      expect(course_cohort).to have_error(:participant_funding, :less_than_milestone_sum)
    end
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
end
