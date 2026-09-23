require "rails_helper"

RSpec.describe Milestone, type: :model do
  describe "paper_trail" do
    it { is_expected.to be_versioned }
  end

  describe "associations" do
    it { is_expected.to belong_to(:course).optional }
  end

  describe "validations" do
    context "when creating a milestone for an invalid declaration type" do
      subject(:milestone) { build(:milestone, declaration_type: "invalid") }

      it { is_expected.to have_error(:declaration_type, :inclusion, "Please choose a declaration type") }
    end

    context "when acceptance window start offset is missing" do
      subject(:milestone) { build(:milestone, acceptance_window_start_offset: nil) }

      it { is_expected.to have_error(:acceptance_window_start_offset, :blank, "can't be blank") }
    end

    context "when acceptance window start offset is present" do
      subject(:milestone) { build(:milestone, acceptance_window_start_offset: 0) }

      it { is_expected.to be_valid }
    end

    context "when acceptance window offsets are not integers" do
      subject(:milestone) do
        build(
          :milestone,
          acceptance_window_start_offset: 1.5,
          acceptance_window_end_offset: 2.5,
        )
      end

      it do
        expect(milestone).to have_error(:acceptance_window_start_offset, :not_an_integer, "must be an integer")
        expect(milestone).to have_error(:acceptance_window_end_offset, :not_an_integer, "must be an integer")
      end
    end

    context "when creating a milestone with a declaration type that already exists for the course" do
      subject(:milestone) { build(:milestone, :started, course:) }

      let(:course) { create(:course) }

      it { is_expected.to have_error(:declaration_type, :taken, "has already been taken") }
    end

    context "when creating a milestone with a declaration type that exists for another course" do
      let(:started_a) { course_milestone(create(:course, name: "a"), :started) }
      let(:started_b) { course_milestone(create(:course, name: "b"), :started) }

      it "is valid" do
        expect(started_a.declaration_type).to eq(started_b.declaration_type)
      end
    end
  end

  describe "#in_declaration_type_order" do
    let(:course) { create(:course) }
    let(:started) { course_milestone(course, :started) }
    let(:retained_1) { create(:milestone, declaration_type: Milestone::RETAINED_1, course:, acceptance_window_start_offset: 1) }
    let(:retained_2) { create(:milestone, declaration_type: Milestone::RETAINED_2, course:, acceptance_window_start_offset: 2) }
    let(:completed) { course_milestone(course, :completed) }

    before do
      # create deliberately out of order
      retained_2
      completed
      started.update!(acceptance_window_start_offset: 0)
      retained_1
    end

    it "orders by declaration_type according to DECLARATION_TYPES" do
      completed.update!(acceptance_window_start_offset: 3)
      expect(Milestone.in_declaration_type_order.where(course:)).to eq([started, retained_1, retained_2, completed])
    end
  end

  describe "#acceptance_window_start_date_for" do
    subject(:acceptance_window_start_date) do
      milestone.acceptance_window_start_date_for(training_starts_at:)
    end

    let(:training_starts_at) { Date.new(2026, 9, 1) }
    let(:milestone) { build(:milestone, acceptance_window_start_offset: 1) }

    it { is_expected.to eq(Date.new(2026, 10, 1)) }

    context "when training_starts_at is blank" do
      let(:training_starts_at) { nil }

      it { is_expected.to be_nil }
    end

    context "when the milestone has no start offset" do
      let(:milestone) { build(:milestone, acceptance_window_start_offset: nil) }

      it { is_expected.to be_nil }
    end
  end

  describe "#acceptance_window_end_date_for" do
    subject(:acceptance_window_end_date) do
      milestone.acceptance_window_end_date_for(training_starts_at:)
    end

    let(:training_starts_at) { Date.new(2026, 9, 1) }
    let(:milestone) { build(:milestone, acceptance_window_end_offset: 1) }

    it { is_expected.to eq(Date.new(2026, 10, 1)) }

    context "when training_starts_at is blank" do
      let(:training_starts_at) { nil }

      it { is_expected.to be_nil }
    end

    context "when the milestone has no end offset" do
      let(:milestone) { build(:milestone, acceptance_window_end_offset: nil) }

      it { is_expected.to be_nil }
    end
  end

  describe "#declaration_sort_order" do
    let(:course) { create(:course) }
    let(:started) { course_milestone(course, :started) }
    let(:completed) { course_milestone(course, :completed) }

    before do
      started.update!(acceptance_window_start_offset: 0)
      completed.update!(acceptance_window_start_offset: 0)
    end

    it "uses declaration type order when milestones have the same acceptance window offset" do
      expect(started.declaration_sort_order <=> completed.declaration_sort_order).to eq(-1)
    end
  end

  describe "#declaration_in_order?" do
    let(:course) { create(:course) }
    let(:started) { course_milestone(course, :started) }
    let(:completed) { course_milestone(course, :completed) }

    before do
      started.update!(acceptance_window_start_offset: 0)
      completed.update!(acceptance_window_start_offset: 0)
    end

    it "is true when all previous milestone declaration types already exist" do
      declaration = create(:declaration, :started, course:, milestone: started)

      expect(completed).to be_declaration_in_order(declarations: Declaration.where(id: declaration.id))
    end

    it "is false when a previous milestone declaration type is missing" do
      expect(completed).not_to be_declaration_in_order(declarations: Declaration.none)
    end
  end

  describe ".all" do
    let(:course) { create(:course) }
    let(:january_milestone) { course_milestone(course, :started) }
    let(:february_milestone) { create(:milestone, course:, declaration_type: Milestone::RETAINED_1, acceptance_window_start_offset: 31) }
    let(:march_milestone) { course_milestone(course, :completed) }

    before do
      # create deliberately out of order
      january_milestone
      february_milestone
    end

    it "orders by acceptance_window_start_offset by default" do
      march_milestone.update!(acceptance_window_start_offset: 59)
      expect(Milestone.all.where(course:)).to eq([january_milestone, february_milestone, march_milestone])
    end
  end
end
