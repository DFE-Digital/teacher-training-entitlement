require "rails_helper"

RSpec.describe Admin::CourseBuilder::Steps::Milestones do
  subject(:step) { described_class.new(milestones:) }

  let(:milestones) { {} }

  describe "#milestone_types" do
    it "defaults to started and completed" do
      expect(described_class.new.milestone_types).to contain_exactly(Milestone::STARTED, Milestone::COMPLETED)
    end

    it "always includes started and completed" do
      expect(step.milestone_types).to contain_exactly(Milestone::STARTED, Milestone::COMPLETED)
    end

    context "when optional milestone types are selected" do
      let(:milestones) do
        {
          Milestone::RETAINED_1 => {
            "selected" => "1",
            "acceptance_window_start_offset" => "3",
            "acceptance_window_end_offset" => "4",
            "payment_percentage" => "40",
          },
        }
      end

      it "keeps the optional selected milestones" do
        expect(step.milestone_types).to contain_exactly(Milestone::STARTED, Milestone::COMPLETED, Milestone::RETAINED_1)
      end
    end
  end

  describe "#required_milestone_type?" do
    it "returns true for started and completed" do
      expect(step.required_milestone_type?(Milestone::STARTED)).to be true
      expect(step.required_milestone_type?(Milestone::COMPLETED)).to be true
    end

    it "returns false for optional milestone types" do
      expect(step.required_milestone_type?(Milestone::RETAINED_1)).to be false
    end
  end

  describe "#milestone_data" do
    it "defaults the acceptance window offsets to 6 and 8 months" do
      expect(step.milestone_data(Milestone::STARTED)).to include(
        "acceptance_window_start_offset" => 6,
        "acceptance_window_end_offset" => 8,
      )
    end
  end

  describe ".permitted_params" do
    it "permits nested milestone attributes" do
      expect(described_class.permitted_params).to eq([{ milestones: {} }])
    end
  end

  describe ".OFFSET_OPTIONS" do
    it "uses month labels with month values" do
      expect(described_class::OFFSET_OPTIONS.first).to eq(["1 month", 1])
      expect(described_class::OFFSET_OPTIONS.last).to eq(["12 months", 12])
    end
  end

  describe "validations" do
    context "when the selected milestone payment percentages do not equal 100" do
      let(:milestones) do
        {
          Milestone::STARTED => {
            "selected" => "1",
            "acceptance_window_start_offset" => "6",
            "acceptance_window_end_offset" => "8",
            "payment_percentage" => "60",
          },
          Milestone::COMPLETED => {
            "selected" => "1",
            "acceptance_window_start_offset" => "6",
            "acceptance_window_end_offset" => "8",
            "payment_percentage" => "41",
          },
        }
      end

      it "is invalid" do
        expect(step).to have_error(:milestones, "payment percentage total must equal 100%")
      end

      context "when the total is less than 100" do
        let(:milestones) do
          {
            Milestone::STARTED => {
              "selected" => "1",
              "acceptance_window_start_offset" => "6",
              "acceptance_window_end_offset" => "8",
              "payment_percentage" => "40",
            },
            Milestone::COMPLETED => {
              "selected" => "1",
              "acceptance_window_start_offset" => "6",
              "acceptance_window_end_offset" => "8",
              "payment_percentage" => "40",
            },
          }
        end

        it "is invalid" do
          expect(step).to have_error(:milestones, "payment percentage total must equal 100%")
        end
      end
    end

    context "when selected milestone payment percentages equal 100" do
      let(:milestones) do
        {
          Milestone::STARTED => {
            "selected" => "1",
            "acceptance_window_start_offset" => "6",
            "acceptance_window_end_offset" => "8",
            "payment_percentage" => "60",
          },
          Milestone::COMPLETED => {
            "selected" => "1",
            "acceptance_window_start_offset" => "6",
            "acceptance_window_end_offset" => "8",
            "payment_percentage" => "40",
          },
          Milestone::RETAINED_1 => {
            "selected" => "0",
            "acceptance_window_start_offset" => "6",
            "acceptance_window_end_offset" => "8",
            "payment_percentage" => "50",
          },
        }
      end

      it "is valid" do
        expect(step).to be_valid
      end
    end

    context "when the offsets are not supported" do
      let(:milestones) do
        {
          Milestone::STARTED => {
            "selected" => "1",
            "acceptance_window_start_offset" => "13",
            "acceptance_window_end_offset" => "14",
            "payment_percentage" => "40",
          },
        }
      end

      it "is invalid" do
        expect(step).to have_error(:"#{Milestone::STARTED}_acceptance_window_start_offset", "is not included in the list")
        expect(step).to have_error(:"#{Milestone::STARTED}_acceptance_window_end_offset", "is not included in the list")
      end
    end
  end
end
