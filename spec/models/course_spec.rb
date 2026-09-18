require "rails_helper"

RSpec.describe Course do
  subject { build(:course) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:identifier).with_message("Identifier already exists, enter a unique one") }
    it { is_expected.to validate_uniqueness_of(:ecf_id).case_insensitive.with_message("ECF ID must be unique").allow_nil }
  end

  describe "defaults" do
    subject(:course) { described_class.create!(name:, identifier:, short_code:) }

    let(:name) { "My Course" }
    let(:identifier) { nil }
    let(:short_code) { nil }

    it "sets the identifier from the name on create when blank" do
      expect(course.identifier).to eq("my-course")
    end

    context "when an identifier is supplied" do
      let(:identifier) { "custom-course" }

      it "does not overwrite it" do
        expect(course.identifier).to eq("custom-course")
      end
    end

    it "sets the short code from the name on create when blank" do
      expect(course.short_code).to eq("NPDMYC")
    end

    context "when a short code is supplied" do
      let(:short_code) { "CUSTOM" }

      it "does not overwrite it" do
        expect(course.short_code).to eq("CUSTOM")
      end
    end
  end
end
