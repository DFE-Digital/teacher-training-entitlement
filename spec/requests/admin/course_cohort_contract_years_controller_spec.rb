require "rails_helper"

RSpec.describe Admin::CourseCohortContractYearsController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  subject { response }

  let(:cohort) { create(:cohort) }
  let(:course) { create(:course) }
  let(:course_cohort) { create(:course_cohort, cohort:, course:, academic_year: 2026) }
  let(:lead_provider) { create(:lead_provider) }
  let(:valid_params) do
    {
      contract_year: {
        lead_provider_id: lead_provider.id,
        academic_year: 2026,
        recruitment_target: 100,
        teacher_funding: "650.50",
        service_fee: "50.25",
      },
    }
  end

  context "when logged in as a super admin" do
    before do
      sign_in_as_admin(super_admin: true)
      course_cohort
    end

    describe "#new" do
      before { get new_admin_cohort_course_contract_year_path(cohort, course) }

      it { is_expected.to have_http_status :success }

      it "defaults the academic year to the course cohort academic year" do
        expect(response.body).to include(course_cohort.academic_year.to_s)
      end
    end

    describe "#create" do
      it "creates the contract year" do
        expect {
          post admin_cohort_course_contract_years_path(cohort, course), params: valid_params
        }.to change(ContractYear, :count).by(1)

        expect(response).to redirect_to(admin_cohort_course_path(cohort, course))
        expect(ContractYear.last).to have_attributes(
          course:,
          lead_provider:,
          academic_year: 2026,
          recruitment_target: 100,
          teacher_funding: BigDecimal("650.50"),
          service_fee: BigDecimal("50.25"),
        )
      end

      context "when academic year is blank" do
        let(:valid_params) do
          {
            contract_year: {
              lead_provider_id: lead_provider.id,
              academic_year: "",
              recruitment_target: 100,
              teacher_funding: "650.50",
              service_fee: "50.25",
            },
          }
        end

        it "creates a generic contract year" do
          post admin_cohort_course_contract_years_path(cohort, course), params: valid_params

          expect(ContractYear.last.academic_year).to be_nil
        end
      end
    end

    describe "#edit" do
      let(:contract_year) { create(:contract_year, course:, lead_provider:, academic_year: 2026) }

      before { get edit_admin_cohort_course_contract_year_path(cohort, course, contract_year) }

      it { is_expected.to have_http_status :success }

      context "when the contract year is generic" do
        let(:contract_year) { create(:contract_year, course:, lead_provider:, academic_year: nil) }

        it "explains that the contract year is generic" do
          expect(response.body).to include("This is a generic contract year.")
        end
      end
    end

    describe "#update" do
      let(:contract_year) { create(:contract_year, course:, lead_provider:, academic_year: 2026) }

      it "updates the contract year" do
        patch admin_cohort_course_contract_year_path(cohort, course, contract_year), params: {
          contract_year: {
            lead_provider_id: lead_provider.id,
            academic_year: 2026,
            recruitment_target: 200,
            teacher_funding: "750.50",
            service_fee: "60.25",
          },
        }

        expect(response).to redirect_to(admin_cohort_course_path(cohort, course))
        expect(contract_year.reload).to have_attributes(
          recruitment_target: 200,
          teacher_funding: BigDecimal("750.50"),
          service_fee: BigDecimal("60.25"),
        )
      end
    end
  end

  context "when logged in as a normal admin" do
    before do
      sign_in_as_admin
      course_cohort
    end

    describe "#new" do
      before { get new_admin_cohort_course_contract_year_path(cohort, course) }

      it { is_expected.to redirect_to admin_cohort_course_path(cohort, course) }
    end
  end
end
