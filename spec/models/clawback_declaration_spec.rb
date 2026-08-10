require "rails_helper"

RSpec.describe ClawbackDeclaration, type: :model do
  subject(:clawback_declaration) { build(:clawback_declaration) }

  it { is_expected.to validate_presence_of(:paid_declaration) }

  describe "enums" do
    it {
      expect(subject).to define_enum_for(:state)
                           .with_values(
                             submitted: "submitted",
                             awaiting_clawback: "awaiting_clawback",
                             clawed_back: "clawed_back",
                           ).backed_by_column_of_type(:enum).with_suffix
    }
  end

  describe "state transition" do
    let(:clawback_declaration) { create(:clawback_declaration, state:) }

    describe ".mark_awaiting_clawback" do
      let(:state) { :submitted }

      it { expect { clawback_declaration.mark_awaiting_clawback }.to change(clawback_declaration, :state).from("submitted").to("awaiting_clawback") }

      context "when not submitted" do
        let(:state) { :awaiting_clawback }

        it { expect { clawback_declaration.mark_awaiting_clawback! }.to raise_error(StateMachines::InvalidTransition) }
      end
    end

    describe ".mark_clawed_back" do
      let(:state) { :awaiting_clawback }

      it { expect { clawback_declaration.mark_clawed_back }.to change(clawback_declaration, :state).from("awaiting_clawback").to("clawed_back") }

      context "when not awaiting_clawback" do
        let(:state) { :clawed_back }

        it { expect { clawback_declaration.mark_clawed_back! }.to raise_error(StateMachines::InvalidTransition) }
      end
    end
  end
end
