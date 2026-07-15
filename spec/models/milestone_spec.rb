require "rails_helper"

RSpec.describe Milestone, type: :model do
  describe "paper_trail" do
    it { is_expected.to be_versioned }
  end

  describe "associations" do
    it { is_expected.to have_many(:milestone_statements) }
    it { is_expected.to have_many(:statements).through(:milestone_statements) }
    it { is_expected.to belong_to(:course_cohort) }
  end

  describe "validations" do
    context "when creating a milestone for an invalid declaration type" do
      subject(:milestone) { build(:milestone, declaration_type: "invalid", statements: [statement]) }

      let(:statement) { create(:statement) }

      it { is_expected.to have_error(:declaration_type, :inclusion, "The declaration type should be one of the ones allowed by the schedule") }
    end

    context "when an acceptance window overlaps another milestone in the same course cohort" do
      subject(:milestone) do
        build(
          :milestone,
          course_cohort:,
          declaration_type: "completed",
          acceptance_window_start_date: Date.new(2026, 1, 15),
          acceptance_window_end_date: Date.new(2026, 2, 15),
        )
      end

      let(:course_cohort) { create(:course_cohort, cohort: create(:cohort, registration_starts_at: Date.new(2026, 1, 1))) }

      before do
        create(
          :milestone,
          course_cohort:,
          declaration_type: "started",
          acceptance_window_start_date: Date.new(2026, 1, 1),
          acceptance_window_end_date: Date.new(2026, 1, 31),
        )
      end

      it { is_expected.to have_error(:base, :overlapping_acceptance_window, "Acceptance window overlaps with another milestone for this course cohort") }
    end

    context "when acceptance windows do not overlap in the same course cohort" do
      let(:course_cohort) { create(:course_cohort) }

      before do
        create(
          :milestone,
          course_cohort:,
          declaration_type: "started",
          acceptance_window_start_date: Date.new(2026, 1, 1),
          acceptance_window_end_date: Date.new(2026, 1, 31),
        )
      end

      it "is valid" do
        milestone = build(
          :milestone,
          course_cohort:,
          declaration_type: "completed",
          acceptance_window_start_date: Date.new(2026, 2, 1),
          acceptance_window_end_date: Date.new(2026, 2, 28),
        )

        expect(milestone).to be_valid
      end
    end

    context "when an acceptance window overlaps a milestone in another course cohort" do
      let(:course_cohort) { create(:course_cohort) }

      before do
        create(
          :milestone,
          course_cohort: create(:course_cohort, cohort: create(:cohort, registration_starts_at: Date.new(2026, 2, 1))),
          declaration_type: "started",
          acceptance_window_start_date: Date.new(2026, 1, 1),
          acceptance_window_end_date: Date.new(2026, 1, 31),
        )
      end

      it "is valid" do
        milestone = build(
          :milestone,
          course_cohort:,
          declaration_type: "completed",
          acceptance_window_start_date: Date.new(2026, 1, 15),
          acceptance_window_end_date: Date.new(2026, 2, 15),
        )

        expect(milestone).to be_valid
      end
    end
  end

  describe "#in_declaration_type_order" do
    let(:course_cohort) { create(:course_cohort) }
    let(:started) { create(:milestone, declaration_type: "started", course_cohort:) }
    let(:retained_1) { create(:milestone, declaration_type: "retained-1", course_cohort:) }
    let(:retained_2) { create(:milestone, declaration_type: "retained-2", course_cohort:) }
    let(:completed) { create(:milestone, declaration_type: "completed", course_cohort:) }

    before do
      # create deliberately out of order
      retained_2
      completed
      started
      retained_1
    end

    it "orders by declaration_type according to DECLARATION_TYPES" do
      expect(Milestone.all.in_declaration_type_order).to eq([started, retained_1, retained_2, completed])
    end
  end

  describe ".all" do
    let(:course_cohort) { create(:course_cohort) }
    let(:january_milestone) do
      create(
        :milestone,
        course_cohort:,
        declaration_type: "started",
        acceptance_window_start_date: Date.new(2026, 1, 1),
        acceptance_window_end_date: Date.new(2026, 1, 31),
      )
    end
    let(:february_milestone) do
      create(
        :milestone,
        course_cohort:,
        declaration_type: "retained-1",
        acceptance_window_start_date: Date.new(2026, 2, 1),
        acceptance_window_end_date: Date.new(2026, 2, 28),
      )
    end
    let(:march_milestone) do
      create(
        :milestone,
        course_cohort:,
        declaration_type: "completed",
        acceptance_window_start_date: Date.new(2026, 3, 1),
        acceptance_window_end_date: Date.new(2026, 3, 31),
      )
    end

    before do
      # create deliberately out of order
      march_milestone
      january_milestone
      february_milestone
    end

    it "orders by acceptance_window_start_date by default" do
      expect(Milestone.all).to eq([january_milestone, february_milestone, march_milestone])
    end
  end
end
