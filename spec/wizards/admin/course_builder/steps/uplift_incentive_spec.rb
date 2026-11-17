require "rails_helper"

RSpec.describe Admin::CourseBuilder::Steps::UpliftIncentive do
  subject(:step) { described_class.new(uplift_percentage:) }

  describe "validations" do
    context "when the uplift percentage is blank" do
      let(:uplift_percentage) { "" }

      it { is_expected.to be_valid }
    end

    %w[0 15 12.5 100].each do |valid_percentage|
      context "when the uplift percentage is #{valid_percentage}" do
        let(:uplift_percentage) { valid_percentage }

        it { is_expected.to be_valid }
      end
    end

    %w[-1 100.01 abc 15%].each do |invalid_percentage|
      context "when the uplift percentage is #{invalid_percentage}" do
        let(:uplift_percentage) { invalid_percentage }

        it "is not valid" do
          expect(step).not_to be_valid
          expect(step.errors[:uplift_percentage]).to contain_exactly("Enter an uplift percentage between 0 and 100")
        end
      end
    end
  end

  describe "#uplift_percentage" do
    context "when the value has spaces" do
      let(:uplift_percentage) { " 15 " }

      it "strips them" do
        expect(step.uplift_percentage).to eq("15")
      end
    end

    context "when the value is only spaces" do
      let(:uplift_percentage) { "  " }

      it "is nil" do
        expect(step.uplift_percentage).to be_nil
      end
    end
  end
end
