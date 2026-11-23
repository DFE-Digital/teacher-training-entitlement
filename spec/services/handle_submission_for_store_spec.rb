require "rails_helper"

RSpec.describe HandleSubmissionForStore do
  subject(:service) { described_class.new(store:) }

  let(:teacher_record_trn) { "0012345" }
  let(:teacher) { create(:teacher, trn: teacher_record_trn, full_name: "John Doe", ecf_id: nil) }
  let(:school) { create(:school, :funding_eligible_establishment_type_code) }
  let(:private_childcare_provider) { create(:private_childcare_provider, :on_early_years_register) }
  let(:cohort) { create(:cohort, :current) }
  let(:course) { Course.reception }
  let(:lead_provider) { LeadProvider.all.sample }
  let!(:course_cohort) { create(:course_cohort, course:, cohort:) }

  let(:store) do
    {
      "current_teacher_id" => teacher.id,
      "course_identifier" => course.identifier,
      "course_cohort_ecf_id" => course_cohort.ecf_id,
      "institution_id" => private_childcare_provider.institution.id,
      "lead_provider_id" => lead_provider.id,
      "teacher_catchment" => Institution::ENGLAND_SUBDIVISION_CODE,
    }
  end

  let(:expected_teacher_attributes) do
    {
      "email" => teacher.email,
      "ecf_id" => teacher.ecf_id,
      "trn" => "0012345",
      "full_name" => teacher.full_name,
      "provider" => nil,
      "raw_tra_provider_data" => nil,
      "date_of_birth" => 30.years.ago.to_date.to_s,
      "one_login_id" => nil,
      "active_alert" => false,
      "archived_email" => nil,
      "archived_at" => nil,
      "national_insurance_number" => nil,
      "notify_teacher_for_future_reg" => false,
      "preferred_name" => teacher.preferred_name,
      "refresh_token" => nil,
      "refresh_token_updated_at" => nil,
      "trn_lookup_status" => nil,
      "trn_requested_at" => nil,
      "feature_flag_id" => teacher.feature_flag_id,
    }
  end

  describe "#call" do
    def stable_as_json(record)
      return if record.nil?

      record
        .as_json(except: %i[id created_at updated_at significantly_updated_at updated_from_tra_at DEPRECATED_school_urn email_updates_status email_updates_unsubscribe_key registration_data])
        .except(*Application.column_names.grep(/teacher.*country/))
    end

    context "when the store includes a teacher object (legacy behaviour)" do
      let(:store) do
        {
          "current_teacher" => teacher,
          "course_identifier" => course.identifier,
          "course_cohort_ecf_id" => course_cohort.ecf_id,
          "lead_provider_id" => lead_provider.id,
        }
      end

      it "creates an application for the teacher" do
        subject.call
        expect(teacher.applications.reload.count).to eq 1
      end
    end

    context "when store includes information from the school path" do
      let(:store) do
        {
          "current_teacher_id" => teacher.id,
          "course_identifier" => course.identifier,
          "course_cohort_ecf_id" => course_cohort.ecf_id,
          "institution_id" => school.institution.id,
          "lead_provider_id" => lead_provider.id,
          "teacher_catchment" => Institution::ENGLAND_SUBDIVISION_CODE,
          "work_setting" => Institution::STATE_FUNDED_INSTITUTION,
        }
      end

      it "stores data from store" do
        expect(stable_as_json(teacher.reload)).to match(expected_teacher_attributes)
        expect(teacher.applications.reload.count).to eq 0
        expect(stable_as_json(teacher.applications.last)).to match(nil)

        subject.call

        expect(stable_as_json(teacher.reload)).to match(expected_teacher_attributes)
        expect(teacher.applications.reload.count).to eq 1
        last_application = teacher.applications.last
        expect(last_application.lead_provider).to eq(lead_provider)
        expect(last_application.application_lead_providers.first.assigned_at).to be_present
        expect(stable_as_json(last_application)).to match({
          "course_cohort_id" => course_cohort.id,
          "ecf_id" => last_application.ecf_id,
          "funded_place" => nil,
          "funding_choice" => nil,
          "funding_eligibility" => "funded",
          "status" => "pending",
          "notes" => nil,
          "institution_id" => school.institution.id,
          "training_starts_at" => course_cohort.training_starts_at.to_s,
          "teacher_id" => teacher.id,
        })
      end

      it "uses country attributes from the selected institution" do
        school.institution.update!(alpha3_country_code: "JEY", subdivision_code: nil)

        subject.call

        application = teacher.applications.last
        expect(application.institution.country_long_name).to eq("Jersey")
        expect(application.institution.alpha3_country_code).to eq("JEY")
      end
    end

    context "when there is a funding choice selected" do
      let(:store) do
        super().merge(
          "funding" => "school",
        )
      end

      context "when there is a funding choice selected and eligible for funding is true" do
        before do
          allow_any_instance_of(FundingEligibility).to receive(:funding_eligibility).and_return(FundingEligibility::FUNDED_ELIGIBILITY_RESULT)
        end

        it "clears the funding choice to nil on the application" do
          subject.call
          expect(teacher.applications.first.reload.funding_choice).to be_nil
        end
      end

      context "when there is a funding choice selected and eligible for funding is false" do
        before do
          allow_any_instance_of(FundingEligibility).to receive(:funding_eligibility).and_return(FundingEligibility::INELIGIBLE_SETTING)
        end

        it "saves the funding choice to school on the application" do
          subject.call
          expect(teacher.applications.first.reload.funding_choice).to eq "school"
        end
      end
    end
  end
end
