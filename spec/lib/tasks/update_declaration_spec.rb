require "rails_helper"

RSpec.describe "update_declaration" do
  describe "update_declaration:clawback" do
    subject(:run_task) { Rake::Task["update_declaration:clawback"].invoke(declaration.ecf_id) }

    let(:statement) { create(:statement, :next_output_fee) }
    let(:declaration) { create(:declaration, :paid, lead_provider: statement.lead_provider, cohort: statement.cohort) }

    after { Rake::Task["update_declaration:clawback"].reenable }

    it "sets the application to awaiting_clawback" do
      run_task
      expect(declaration.reload.state).to eq "awaiting_clawback"
    end
  end

  describe "update_declaration:void" do
    subject(:run_task) { Rake::Task["update_declaration:void"].invoke(declaration.ecf_id) }

    let(:statement) { create(:statement, :next_output_fee) }
    let(:declaration) { create(:declaration, lead_provider: statement.lead_provider, cohort: statement.cohort) }

    after { Rake::Task["update_declaration:void"].reenable }

    it "voids the declaration" do
      run_task
      expect(declaration.reload.state).to eq "voided"
    end
  end
end
