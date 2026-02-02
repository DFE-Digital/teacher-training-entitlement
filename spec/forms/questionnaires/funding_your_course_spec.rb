require "rails_helper"

RSpec.describe Questionnaires::FundingYourCourse, type: :model do
  describe "#previous_step" do
    subject { described_class.new(wizard:).previous_step }

    let(:wizard) do
      RegistrationWizard.new(
        current_step: :funding_your_course,
        store: {},
        request: nil,
        current_user: build_stubbed(:user),
      )
    end

    it { is_expected.to eq(:ineligible_for_funding) }
  end
end
