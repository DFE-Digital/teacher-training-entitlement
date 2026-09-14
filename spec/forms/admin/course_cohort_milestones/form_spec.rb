require "rails_helper"

RSpec.describe Admin::CourseCohortMilestones::Form, type: :model do
  describe ".new" do
    subject(:form) { described_class.new(attributes) }

    let(:attributes) do
      {
        declaration_type: "started",
        payment_percentage: "40",
        acceptance_window_start_offset: "0",
        acceptance_window_end_offset: "30",
        unexpected: "ignored",
      }
    end

    it "maps the milestone attributes" do
      expect(form).to have_attributes(
        declaration_type: "started",
        payment_percentage: BigDecimal("40"),
        acceptance_window_start_offset: 0,
        acceptance_window_end_offset: 30,
      )
    end

    it "exposes normalized attributes" do
      expect(form.attributes.symbolize_keys).to include(
        declaration_type: "started",
        payment_percentage: BigDecimal("40"),
      )
    end

    it "exposes milestone attributes with payment percentage as a decimal ratio" do
      expect(form.milestone_attributes).to include(
        declaration_type: "started",
        payment_percentage: BigDecimal("0.4"),
      )
    end

    context "when form params are missing" do
      let(:attributes) { {} }

      it "builds an empty form" do
        expect(form.attributes.symbolize_keys).to eq(
          declaration_type: nil,
          payment_percentage: nil,
          acceptance_window_start_offset: nil,
          acceptance_window_end_offset: nil,
        )
      end
    end
  end

  describe "with milestone attributes" do
    subject(:form) do
      described_class.new(milestone.attributes)
    end

    let(:milestone) do
      create(
        :milestone,
        declaration_type: "started",
        payment_percentage: BigDecimal("0.4"),
        acceptance_window_start_offset: 0,
        acceptance_window_end_offset: 30,
      )
    end

    it "maps milestone attributes onto the form" do
      expect(form).to have_attributes(
        declaration_type: "started",
        payment_percentage: BigDecimal("40"),
        acceptance_window_start_offset: 0,
        acceptance_window_end_offset: 30,
      )
    end
  end

  describe "#declaration_type_taken?" do
    subject(:form) { described_class.new({}, taken_declaration_types: %w[started]) }

    it "returns true when the declaration type has already been taken" do
      expect(form.declaration_type_taken?("started")).to be true
    end

    it "returns false when the declaration type is still available" do
      expect(form.declaration_type_taken?("completed")).to be false
    end
  end
end
