# frozen_string_literal: true

require "rails_helper"

RSpec.describe Statements::OutputPaymentCalculator do
  subject { described_class.call(contract:, total_participants:) }

  let(:contract_template) { create(:contract_template, per_participant: 800) }
  let(:contract) { create(:contract, contract_template:) }
  let(:total_participants) { 10 }

  let(:expected_result) do
    {
      participants: total_participants,
      per_participant: 160,
      subtotal: 1600,
    }
  end

  it { is_expected.to eq(expected_result) }
end
