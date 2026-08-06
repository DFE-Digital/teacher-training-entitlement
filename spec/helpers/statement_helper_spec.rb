require "rails_helper"

RSpec.describe StatementHelper, type: :helper do
  describe "#statement_name" do
    subject { statement_name(statement) }

    let(:statement) { build(:statement, start_date: Date.new(2024, 3, 1)) }

    it { is_expected.to eq("March 2024") }
  end

  describe "#statement_period" do
    subject { statement_period(statement) }

    let(:statement) { build(:statement, start_date: Date.new(2024, 3, 1), deadline_date: Date.new(2024, 3, 31)) }

    it { is_expected.to eq("1 Mar 2024-31 Mar 2024") }
  end
end
