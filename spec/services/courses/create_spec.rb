require "rails_helper"

RSpec.describe Courses::Create do
  describe "#call" do
    subject(:service) { described_class.new(state_store:) }

    context "when creating the course succeeds" do
      let(:lead_provider) { create(:lead_provider) }
      let(:course_details) do
        Admin::CourseBuilder::StateStore::CourseDetails.new(
          name: "New course",
          identifier: "new-course",
          short_code: "NEWCOUR",
          course_group: "send",
          description: "New course description",
        )
      end
      let(:selected_lead_provider) do
        Admin::CourseBuilder::StateStore::SelectedLeadProvider.new(
          lead_provider:,
          url: "https://example.com/course",
          email: "provider@example.com",
        )
      end
      let(:selected_contract_financial) do
        Admin::CourseBuilder::StateStore::SelectedContractFinancial.new(
          lead_provider:,
          academic_year: 2027,
          teacher_funding: "650",
          recruitment_target: "3000",
        )
      end
      let(:milestone_configs) do
        [
          Admin::CourseBuilder::StateStore::MilestoneConfig.new(
            declaration_type: Milestone::STARTED,
            acceptance_window_start_offset: 1,
            acceptance_window_end_offset: 2,
            payment_percentage: "60",
          ),
          Admin::CourseBuilder::StateStore::MilestoneConfig.new(
            declaration_type: Milestone::COMPLETED,
            acceptance_window_start_offset: 3,
            acceptance_window_end_offset: 4,
            payment_percentage: "40",
          ),
        ]
      end
      let(:state_store) do
        instance_double(
          Admin::CourseBuilder::StateStore,
          course_details:,
          selected_lead_providers: [selected_lead_provider],
          selected_contract_financials: selected_contract_financials,
          milestone_configs:,
        )
      end
      let(:selected_contract_financials) { [selected_contract_financial] }

      around do |example|
        travel_to(Date.new(2028, 4, 15)) { example.run }
      end

      it "creates the course" do
        service.call

        expect(service.course).to have_attributes(
          name: "New course",
          identifier: "new-course",
          short_code: "NEWCOUR",
          course_group: "send",
          description: "New course description",
        )
      end

      it "creates milestones from the selected milestone configs" do
        service.call

        expect(service.course.milestones.pluck(:declaration_type, :acceptance_window_start_offset, :acceptance_window_end_offset, :payment_percentage)).to contain_exactly(
          [Milestone::STARTED, 1, 2, BigDecimal("0.6")],
          [Milestone::COMPLETED, 3, 4, BigDecimal("0.4")],
        )
      end

      it "creates a generic contract year with the lead provider URL and email" do
        service.call

        contract_year = ContractYear.find_by!(course: service.course, lead_provider:, academic_year: nil)

        expect(contract_year).to have_attributes(
          course_url: "https://example.com/course",
          email: "provider@example.com",
        )
      end

      it "creates a separate contract year with the financials when academic year is set" do
        service.call

        contract_year = ContractYear.find_by!(course: service.course, lead_provider:, academic_year: 2027)

        expect(contract_year).to have_attributes(
          teacher_funding: 650,
          recruitment_target: 3000,
          course_url: nil,
          email: nil,
        )
      end

      context "when the contract financials are generic" do
        let(:selected_contract_financial) do
          Admin::CourseBuilder::StateStore::SelectedContractFinancial.new(
            lead_provider:,
            academic_year: nil,
            teacher_funding: "650",
            recruitment_target: "3000",
          )
        end

        let(:selected_contract_financials) { [selected_contract_financial] }

        it "adds the financials to the generic contract year" do
          service.call

          expect(ContractYear.where(course: service.course, lead_provider:).count).to eq(1)
          expect(ContractYear.find_by!(course: service.course, lead_provider:, academic_year: nil)).to have_attributes(
            course_url: "https://example.com/course",
            email: "provider@example.com",
            teacher_funding: 650,
            recruitment_target: 3000,
          )
        end
      end

      context "when there are multiple specific academic years" do
        let(:selected_contract_financials) do
          [
            selected_contract_financial,
            Admin::CourseBuilder::StateStore::SelectedContractFinancial.new(
              lead_provider:,
              academic_year: 2028,
              teacher_funding: "700",
              recruitment_target: "3500",
            ),
          ]
        end

        it "creates a contract year for each academic year" do
          service.call

          expect(ContractYear.where(course: service.course, lead_provider:).pluck(:academic_year)).to contain_exactly(nil, 2027, 2028)
        end
      end
    end

    context "when creating the course fails" do
      let(:course_details) do
        Admin::CourseBuilder::StateStore::CourseDetails.new(
          name: "Existing course",
          identifier: existing_course.identifier,
          short_code: "EXIST",
          course_group: "reception",
          description: "Existing course description",
        )
      end
      let(:state_store) { instance_double(Admin::CourseBuilder::StateStore, course_details:, milestone_configs: []) }
      let!(:existing_course) { create(:course, identifier: "existing-course") }

      it "adds the failing model name to validation errors" do
        service.call

        expect(service.errors[:base]).to contain_exactly("Course: Identifier Identifier already exists, enter a unique one")
      end
    end
  end
end
