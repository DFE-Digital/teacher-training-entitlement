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

  describe "uplift details" do
    let(:institution) { create(:institution) }

    context "when an uplift percentage was entered" do
      before do
        repository.save(
          {
            uplift_percentage: "15",
            uplift_institution_ids: [institution.id, 0],
          },
        )
      end

      it { is_expected.to be_uplift_incentive }

      it "returns the uplift percentage as entered" do
        expect(state_store.uplift_percentage).to eq("15")
      end

      it "returns the selected institutions that exist" do
        expect(state_store.selected_uplift_institutions).to contain_exactly(institution)
      end
    end

    context "when no uplift percentage was entered" do
      before do
        repository.save(
          {
            uplift_percentage: "",
            uplift_institution_ids: [institution.id],
          },
        )
      end

      it { is_expected.not_to be_uplift_incentive }

      it "returns no uplift percentage" do
        expect(state_store.uplift_percentage).to be_nil
      end

      it "ignores institutions left from an earlier answer" do
        expect(state_store.selected_uplift_institutions).to be_empty
      end
    end
  end

  describe "#selected_delivery_partnerships" do
    let(:selected_lead_provider) { create(:lead_provider) }
    let(:removed_lead_provider) { create(:lead_provider) }
    let(:delivery_partner) { create(:delivery_partner) }

    before do
      repository.save(
        {
          lead_providers: {
            selected_lead_provider.id.to_s => { "selected" => "1" },
            removed_lead_provider.id.to_s => { "selected" => "0" },
          },
          delivery_partners: {
            selected_lead_provider.id.to_s => {
              delivery_partner.id.to_s => delivery_partner.id.to_s,
              "999999" => "999999",
            },
            removed_lead_provider.id.to_s => {
              delivery_partner.id.to_s => delivery_partner.id.to_s,
            },
          },
        },
      )
    end

    it "only returns partnerships for lead providers still selected" do
      expect(state_store.selected_delivery_partnerships.map(&:lead_provider)).to contain_exactly(selected_lead_provider)
    end

    it "only returns partnerships for delivery partners that exist" do
      expect(state_store.selected_delivery_partnerships.map(&:delivery_partner)).to contain_exactly(delivery_partner)
    end
  end
end
