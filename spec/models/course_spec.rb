require "rails_helper"

RSpec.describe Course do
  subject { build(:course) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:identifier).with_message("Identifier already exists, enter a unique one") }
    it { is_expected.to validate_uniqueness_of(:ecf_id).case_insensitive.with_message("ECF ID must be unique").allow_nil }
  end

  describe "#short_code" do
    let(:course) { create(:course, :tte_early_years) }

    it "returns the short code" do
      expect(course.short_code).to eq("TTEEY")
    end

    context "when a NPQ course short code is missing from the mapping" do
      let(:course) { create(:course, identifier: "npq-anything") }

      it "logs an error" do
        expect(Rails.logger).to receive(:warn)
        expect(Sentry).to receive(:capture_message)

        course.short_code
      end

      it "returns nil" do
        expect(course.short_code).to be_nil
      end
    end
  end
end
