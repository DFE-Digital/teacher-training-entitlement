require "rails_helper"

RSpec.describe Admin::CourseBuilder::StateStore do
  subject(:state_store) { described_class.new(repository:) }

  let(:repository) { DfE::Wizard::Repository::InMemory.new }

  describe "#course_details" do
    before do
      repository.save(
        {
          name: "SEND teaching",
          identifier: "send-teaching",
          short_code: "SEND",
          course_group: "send",
          description: "SEND teaching description",
        },
      )
    end

    it "returns the selected course group" do
      expect(state_store.course_details.course_group).to eq("send")
    end
  end

  describe "#milestone_configs" do
    before do
      repository.save(
        {
          milestones: {
            Milestone::STARTED => {
              "selected" => "1",
              "acceptance_window_start_offset" => 1,
              "acceptance_window_end_offset" => 2,
              "payment_percentage" => "60",
            },
            Milestone::COMPLETED => {
              "selected" => "1",
              "acceptance_window_start_offset" => 3,
              "acceptance_window_end_offset" => 4,
              "payment_percentage" => "40",
            },
            Milestone::RETAINED_1 => {
              "selected" => "0",
              "acceptance_window_start_offset" => 5,
              "acceptance_window_end_offset" => 6,
              "payment_percentage" => "20",
            },
          },
        },
      )
    end

    it "returns the milestone types with their selected offsets" do
      expect(state_store.milestone_configs).to contain_exactly(
        have_attributes(
          declaration_type: Milestone::STARTED,
          acceptance_window_start_offset: 1,
          acceptance_window_end_offset: 2,
          payment_percentage: "60",
        ),
        have_attributes(
          declaration_type: Milestone::COMPLETED,
          acceptance_window_start_offset: 3,
          acceptance_window_end_offset: 4,
          payment_percentage: "40",
        ),
      )
    end
  end

  describe "#selected_contract_financials" do
    let(:selected_lead_provider) { create(:lead_provider) }
    let(:unselected_lead_provider) { create(:lead_provider) }

    before do
      repository.save(
        {
          lead_providers: {
            selected_lead_provider.id.to_s => { "selected" => "1" },
          },
          contract_financials: {
            "generic" => {
              selected_lead_provider.id.to_s => {
                "selected" => "1",
                "teacher_funding" => "650",
                "recruitment_target" => "3000",
              },
              unselected_lead_provider.id.to_s => {
                "selected" => "1",
                "teacher_funding" => "800",
                "recruitment_target" => "4000",
              },
            },
            "2027" => {
              selected_lead_provider.id.to_s => {
                "selected" => "1",
                "teacher_funding" => "700",
                "recruitment_target" => "3500",
              },
            },
            "2028" => {
              selected_lead_provider.id.to_s => {
                "selected" => "1",
                "teacher_funding" => "750",
                "recruitment_target" => "4000",
              },
            },
          },
        },
      )
    end

    it "only returns contract financials for lead providers selected in the lead provider step" do
      expect(state_store.selected_contract_financials.map(&:lead_provider)).to contain_exactly(
        selected_lead_provider,
        selected_lead_provider,
        selected_lead_provider,
      )
    end

    it "returns generic and specific academic year contract financials" do
      expect(state_store.selected_contract_financials.map(&:academic_year)).to contain_exactly(nil, 2027, 2028)
    end
  end
end
