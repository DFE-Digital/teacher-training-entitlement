require "rails_helper"

RSpec.describe Courses::Create do
  describe "#call" do
    subject(:service) { described_class.new(state_store:) }

    context "when creating the course succeeds" do
      let(:cohort) { create(:cohort, registration_starts_at: Date.new(2026, 9, 1), registration_ends_at: Date.new(2026, 10, 1)) }
      let(:lead_provider) { create(:lead_provider) }
      let(:course_details) do
        Admin::CourseBuilder::StateStore::CourseDetails.new(
          name: "New course",
          identifier: "new-course",
          short_code: "NEWCOUR",
          description: "New course description",
        )
      end
      let(:registration_period) do
        Admin::CourseBuilder::StateStore::RegistrationPeriod.new(
          cohort:,
          starts_at: cohort.registration_starts_at,
          length_in_months: nil,
          ends_at: cohort.registration_ends_at,
        )
      end
      let(:training_period) do
        Admin::CourseBuilder::StateStore::TrainingPeriod.new(
          starts_at: Date.new(2026, 10, 2),
          ends_at: Date.new(2027, 1, 2),
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
          academic_year: "2027",
          teacher_funding: "650",
          recruitment_target: "3000",
        )
      end
      let(:state_store) do
        instance_double(
          Admin::CourseBuilder::StateStore,
          course_details:,
          registration_period:,
          training_period:,
          selected_lead_providers: [selected_lead_provider],
          selected_contract_financials: [selected_contract_financial],
          milestone_types: [Milestone::STARTED],
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
    end

    context "when creating the course fails" do
      let(:course_details) do
        Admin::CourseBuilder::StateStore::CourseDetails.new(
          name: "Existing course",
          identifier: existing_course.identifier,
          short_code: "EXIST",
          description: "Existing course description",
        )
      end
      let(:state_store) { instance_double(Admin::CourseBuilder::StateStore, course_details:) }
      let!(:existing_course) { create(:course, identifier: "existing-course") }

      it "adds the failing model name to validation errors" do
        service.call

        expect(service.errors[:base]).to contain_exactly("Course: Identifier Identifier already exists, enter a unique one")
      end
    end
  end
end
