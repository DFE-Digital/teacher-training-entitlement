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

    context "when acceptance window start date is missing" do
      subject(:milestone) { build(:milestone, acceptance_window_start_date: nil) }

      it { is_expected.to have_error(:acceptance_window_start_date, :blank, "can't be blank") }
    end

    context "when creating a milestone with a declaration type that already exists for the course cohort" do
      subject(:milestone) do
        build(
          :milestone,
          course_cohort:,
          declaration_type: "started",
          acceptance_window_start_date: Date.new(2026, 2, 1),
          acceptance_window_end_date: Date.new(2026, 2, 28),
        )
      end

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

      it { is_expected.to have_error(:declaration_type, :taken, "has already been taken") }
    end

    context "when creating a milestone with a declaration type that exists for another course cohort" do
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
          declaration_type: "started",
          acceptance_window_start_date: Date.new(2026, 1, 1),
          acceptance_window_end_date: Date.new(2026, 1, 31),
        )

        expect(milestone).to be_valid
      end
    end

    describe "participant_funding validation" do
      let(:course_cohort) { create(:course_cohort, participant_funding:) }

      before { create(:milestone, course_cohort:, payment_amount: 600) }

      context "when sum would exceed participant_funding" do
        let(:participant_funding) { 1000 }

        it "is invalid when adding a milestone" do
          milestone = build(:milestone, :completed, course_cohort:, payment_amount: 500)

          expect(milestone).to have_error(:payment_amount, :exceeds_participant_funding)
        end

        it "is invalid when updating an existing milestone" do
          milestone = create(:milestone, :completed, course_cohort:, payment_amount: 300)

          milestone.payment_amount = 500

          expect(milestone).to have_error(:payment_amount, :exceeds_participant_funding)
        end
      end

      context "when sum equals participant_funding" do
        let(:participant_funding) { 1000 }

        it "is valid" do
          milestone = build(:milestone, :completed, course_cohort:, payment_amount: 400)

          expect(milestone).to be_valid
        end
      end

      context "when participant_funding is nil" do
        let(:participant_funding) { nil }

        it "is valid" do
          milestone = build(:milestone, :completed, course_cohort:, payment_amount: 500)

          expect(milestone).to be_valid
        end
      end
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
    let(:started) do
      create(
        :milestone,
        declaration_type: "started",
        course_cohort:,
        acceptance_window_start_date: Date.new(2026, 1, 1),
        acceptance_window_end_date: Date.new(2026, 1, 31),
      )
    end
    let(:retained_1) do
      create(
        :milestone,
        declaration_type: "retained-1",
        course_cohort:,
        acceptance_window_start_date: Date.new(2026, 2, 1),
        acceptance_window_end_date: Date.new(2026, 2, 28),
      )
    end
    let(:retained_2) do
      create(
        :milestone,
        declaration_type: "retained-2",
        course_cohort:,
        acceptance_window_start_date: Date.new(2026, 3, 1),
        acceptance_window_end_date: Date.new(2026, 3, 31),
      )
    end
    let(:completed) do
      create(
        :milestone,
        declaration_type: "completed",
        course_cohort:,
        acceptance_window_start_date: Date.new(2026, 4, 1),
        acceptance_window_end_date: Date.new(2026, 4, 30),
      )
    end

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
