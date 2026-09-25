# frozen_string_literal: true

require "rails_helper"

RSpec.describe CourseCohorts::SetupForm, type: :model do
  subject(:form) do
    described_class.new(
      course:,
      cohort_id:,
      training_starts_at:,
    )
  end

  let(:cohort) { create(:cohort, registration_starts_at: Date.new(2027, 9, 1)) }
  let(:course) { create(:course) }
  let(:cohort_id) { cohort.id }
  let(:training_starts_at) { { 1 => 2027, 2 => 9, 3 => 1 } }

  describe "validations" do
    it { is_expected.to validate_presence_of(:course) }
    it { is_expected.to validate_presence_of(:cohort_id) }

    describe "#valid_training_dates" do
      context "with a valid training start date" do
        it "does not add an error on training_starts_at" do
          form.valid?

          expect(form.errors[:training_starts_at]).to be_empty
        end
      end

      context "with no training start date" do
        it "does not add an error on training_ends_at" do
          form.valid?

          expect(form.errors[:training_starts_at]).to be_empty
        end
      end

      context "with an invalid training start date" do
        let(:training_starts_at) { "not-a-date" }

        it "adds an error on training_starts_at" do
          form.valid?

          expect(form.errors[:training_starts_at]).to include("Enter a valid date")
        end
      end
    end
  end

  describe "#cohort_options" do
    let!(:existing_cohort) { create(:cohort, registration_starts_at: Date.new(2027, 1, 1)) }
    let!(:older_cohort) { create(:cohort, registration_starts_at: Date.new(2026, 1, 1)) }
    let!(:newer_cohort) { create(:cohort, registration_starts_at: Date.new(2028, 1, 1)) }

    before do
      create(:course_cohort, course:, cohort: existing_cohort)
    end

    it "returns cohorts not already assigned to the course, newest first" do
      cohorts = form.cohort_options

      expect(cohorts).to include(older_cohort, newer_cohort)
      expect(cohorts).not_to include(existing_cohort)
      expect(cohorts.map(&:registration_starts_at)).to eq(cohorts.map(&:registration_starts_at).sort.reverse)
    end
  end

  describe "#selected_cohort" do
    context "when a cohort matches the given cohort_id" do
      it "returns the cohort" do
        expect(form.selected_cohort).to eq(cohort)
      end
    end

    context "when no cohort matches the given cohort_id" do
      let(:cohort_id) { 0 }

      it "returns nil" do
        expect(form.selected_cohort).to be_nil
      end
    end
  end
end
