require "rails_helper"

RSpec.describe Admin::CourseCohortMilestones::Form, type: :model do
  describe ".new" do
    subject(:form) { described_class.new(attributes) }

    let(:attributes) do
      {
        declaration_type: "started",
        payment_amount: "123.45",
        "acceptance_window_start_date(1i)": "2026",
        "acceptance_window_start_date(2i)": "1",
        "acceptance_window_start_date(3i)": "1",
        "acceptance_window_end_date(1i)": "2026",
        "acceptance_window_end_date(2i)": "1",
        "acceptance_window_end_date(3i)": "31",
        unexpected: "ignored",
      }
    end

    it "maps the milestone attributes" do
      expect(form).to have_attributes(
        declaration_type: "started",
        payment_amount: BigDecimal("123.45"),
        acceptance_window_start_date: Date.new(2026, 1, 1),
        acceptance_window_end_date: Date.new(2026, 1, 31),
      )
    end

    it "exposes normalized attributes" do
      expect(form.attributes.symbolize_keys).to include(
        declaration_type: "started",
        payment_amount: BigDecimal("123.45"),
      )
    end

    context "when form params are missing" do
      let(:attributes) { {} }

      it "builds an empty form" do
        expect(form.attributes.symbolize_keys).to eq(
          declaration_type: nil,
          payment_amount: nil,
          acceptance_window_start_date: nil,
          acceptance_window_end_date: nil,
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
        payment_amount: BigDecimal("123.45"),
        acceptance_window_start_date: Date.new(2026, 1, 1),
        acceptance_window_end_date: Date.new(2026, 1, 31),
      )
    end

    it "maps milestone attributes onto the form" do
      expect(form).to have_attributes(
        declaration_type: "started",
        payment_amount: BigDecimal("123.45"),
        acceptance_window_start_date: Date.new(2026, 1, 1),
        acceptance_window_end_date: Date.new(2026, 1, 31),
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
