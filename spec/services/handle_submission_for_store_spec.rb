require "rails_helper"

RSpec.describe HandleSubmissionForStore do
  subject(:service) { described_class.new(store:) }

  let(:user_record_trn) { "0012345" }
  let(:user) { create(:user, trn: user_record_trn, full_name: "John Doe", ecf_id: nil) }
  let(:school) { create(:school, :funding_eligible_establishment_type_code) }
  let(:private_childcare_provider) { create(:private_childcare_provider, :on_early_years_register) }
  let(:cohort) { create(:cohort, :current) }
  let(:courses) { Course.where(identifier: "tte-early-years") }
  let(:course) { courses.sample }
  let(:lead_provider) { LeadProvider.all.sample }

  let(:store) do
    {
      "current_user_id" => user.id,
      "course_identifier" => course.identifier,
      "institution_id" => private_childcare_provider.institution.id,
      "lead_provider_id" => lead_provider.id,
      "works_in_childcare" => "yes",
      "works_in_school" => "no",
      "kind_of_nursery" => "private_nursery",
      "teacher_catchment" => "england",
    }
  end

  let(:expected_user_attributes) do
    {
      "email" => user.email,
      "ecf_id" => user.ecf_id,
      "trn" => "0012345",
      "full_name" => user.full_name,
      "get_an_identity_id_synced_to_ecf" => false,
      "provider" => nil,
      "raw_tra_provider_data" => nil,
      "date_of_birth" => 30.years.ago.to_date.to_s,
      "uid" => nil,
      "active_alert" => false,
      "archived_email" => nil,
      "archived_at" => nil,
      "national_insurance_number" => nil,
      "notify_user_for_future_reg" => false,
      "preferred_name" => user.preferred_name,
      "trn_auto_verified" => false,
      "trn_lookup_status" => nil,
      "trn_verified" => false,
      "feature_flag_id" => user.feature_flag_id,
    }
  end

  before do
    travel_to(Date.new(cohort.start_year, 9, 26))
    allow_any_instance_of(School).to receive(:pp50?).and_return(false)
  end

  describe "#call" do
    def stable_as_json(record)
      record.as_json(except: %i[id created_at updated_at significantly_updated_at updated_from_tra_at DEPRECATED_school_urn email_updates_status email_updates_unsubscribe_key])
    end

    context "when the store includes a user object (legacy behaviour)" do
      let(:store) do
        {
          "current_user" => user,
          "course_identifier" => course.identifier,
          "lead_provider_id" => lead_provider.id,
        }
      end

      it "creates an application for the user" do
        subject.call
        expect(user.applications.reload.count).to eq 1
      end
    end

    context "when store includes information from the school path" do
      let(:store) do
        {
          "current_user_id" => user.id,
          "course_identifier" => course.identifier,
          "institution_id" => school.institution.id,
          "lead_provider_id" => lead_provider.id,
          "works_in_school" => "yes",
          "teacher_catchment" => "england",
          "work_setting" => "a_school",
          "referred_by_return_to_teaching_adviser" => "no",
          "trn" => "1234321",
        }
      end

      it "stores data from store" do
        expect(stable_as_json(user.reload)).to match(expected_user_attributes)
        expect(user.applications.reload.count).to eq 0
        expect(stable_as_json(user.applications.last)).to match(nil)

        subject.call

        expect(stable_as_json(user.reload)).to match(expected_user_attributes)
        expect(user.applications.reload.count).to eq 1
        last_application = user.applications.last
        expect(stable_as_json(last_application)).to match({
          "course_id" => course.id,
          "schedule_id" => nil,
          "ecf_id" => last_application.ecf_id,
          "eligible_for_funding" => true,
          "funded_place" => nil,
          "funding_choice" => nil,
          "funding_eligiblity_status_code" => "funded",
          "kind_of_nursery" => nil,
          "lead_provider_approval_status" => "pending",
          "participant_outcome_state" => nil,
          "lead_provider_id" => lead_provider.id,
          "notes" => nil,
          "cohort_id" => last_application.cohort_id,
          "institution_id" => school.institution.id,
          "targeted_support_funding_eligibility" => false,
          "teacher_catchment" => "england",
          "teacher_catchment_country" => "United Kingdom of Great Britain and Northern Ireland",
          "teacher_catchment_iso_country_code" => "GBR",
          "training_status" => nil,
          "ukprn" => school.ukprn,
          "number_of_pupils" => nil,
          "primary_establishment" => false,
          "user_id" => user.id,
          "works_in_nursery" => nil,
          "works_in_childcare" => false,
          "works_in_school" => true,
          "work_setting" => "a_school",
          "raw_application_data" => store.except("current_user_id"),
          "referred_by_return_to_teaching_adviser" => "no",
          "accepted_at" => nil,
          "on_submission_trn" => "1234321",
          "review_status" => nil,
          "reason_for_rejection" => nil,
        })
      end
    end

    context "when store includes information from the early years path", :npq do
      let(:courses) { [Course.ehco] }
      let(:store) do
        {
          "current_user_id" => user.id,
          "course_identifier" => course.identifier,
          "institution_id" => private_childcare_provider.institution.id,
          "lead_provider_id" => lead_provider.id,
          "works_in_childcare" => "yes",
          "works_in_school" => "no",
          "kind_of_nursery" => "private_nursery",
          "teacher_catchment" => "england",
          "work_setting" => "early_years_or_childcare",
          "referred_by_return_to_teaching_adviser" => "no",
          "on_submission_trn" => nil,
        }
      end

      it "stores data from store" do
        expect(stable_as_json(user.reload)).to match(expected_user_attributes)
        expect(user.applications.reload.count).to eq 0
        expect(stable_as_json(user.applications.last)).to match(nil)

        subject.call

        expect(stable_as_json(user.reload)).to match(expected_user_attributes)
        expect(user.applications.reload.count).to eq 1
        last_application = user.applications.last
        expect(stable_as_json(last_application)).to match({
          "course_id" => course.id,
          "schedule_id" => nil,
          "ecf_id" => last_application.ecf_id,
          "eligible_for_funding" => false,
          "funded_place" => nil,
          "funding_choice" => nil,
          "lead_provider_approval_status" => "pending",
          "participant_outcome_state" => nil,
          "funding_eligiblity_status_code" => "not_new_headteacher_requesting_ehco",
          "lead_provider_id" => lead_provider.id,
          "notes" => nil,
          "kind_of_nursery" => "private_nursery",
          "cohort_id" => last_application.cohort_id,
          "institution_id" => private_childcare_provider.institution.id,
          "targeted_support_funding_eligibility" => false,
          "teacher_catchment" => "england",
          "teacher_catchment_country" => "United Kingdom of Great Britain and Northern Ireland",
          "teacher_catchment_iso_country_code" => "GBR",
          "training_status" => nil,
          "ukprn" => nil,
          "number_of_pupils" => 0,
          "primary_establishment" => false,
          "user_id" => user.id,
          "works_in_nursery" => nil,
          "works_in_childcare" => true,
          "works_in_school" => false,
          "work_setting" => "early_years_or_childcare",
          "raw_application_data" => store.except("current_user_id"),
          "referred_by_return_to_teaching_adviser" => "no",
          "accepted_at" => nil,
          "on_submission_trn" => nil,
          "review_status" => nil,
          "reason_for_rejection" => nil,
        })
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
          allow_any_instance_of(FundingEligibility).to receive(:funding_eligiblity_status_code).and_return(FundingEligibility::FUNDED_ELIGIBILITY_RESULT)
        end

        it "clears the funding choice to nil on the application" do
          subject.call
          expect(user.applications.first.reload.funding_choice).to be_nil
        end
      end

      context "when there is a funding choice selected and eligible for funding is false" do
        before do
          allow_any_instance_of(FundingEligibility).to receive(:funding_eligiblity_status_code).and_return(FundingEligibility::INELIGIBLE_SETTING)
        end

        it "saves the funding choice to school on the application" do
          subject.call
          expect(user.applications.first.reload.funding_choice).to eq "school"
        end
      end
    end

    context "when teacher catchment is not in the UK catchment area" do
      let(:store) do
        {
          "current_user_id" => user.id,
          "course_identifier" => course.identifier,
          "institution_id" => private_childcare_provider.institution.id,
          "lead_provider_id" => lead_provider.id,
          "works_in_childcare" => "yes",
          "works_in_school" => "no",
          "kind_of_nursery" => "private_nursery",
          "teacher_catchment" => "another",
          "teacher_catchment_country" => "spain",
          "work_setting" => "early_years_or_childcare",
          "referred_by_return_to_teaching_adviser" => "no",
          "on_submission_trn" => nil,
        }
      end

      it "stores data from store" do
        subject.call

        expect(stable_as_json(user.applications.last)).to match({
          "course_id" => course.id,
          "schedule_id" => nil,
          "ecf_id" => user.applications.last.ecf_id,
          "eligible_for_funding" => false,
          "funded_place" => nil,
          "funding_choice" => nil,
          "funding_eligiblity_status_code" => "not_in_england",
          "kind_of_nursery" => "private_nursery",
          "lead_provider_approval_status" => "pending",
          "participant_outcome_state" => nil,
          "lead_provider_id" => lead_provider.id,
          "notes" => nil,
          "cohort_id" => cohort.id,
          "institution_id" => nil,
          "targeted_support_funding_eligibility" => false,
          "teacher_catchment" => "another",
          "teacher_catchment_country" => "spain",
          "teacher_catchment_iso_country_code" => "ESP",
          "training_status" => nil,
          "ukprn" => nil,
          "number_of_pupils" => 0,
          "primary_establishment" => false,
          "user_id" => user.id,
          "works_in_nursery" => nil,
          "works_in_childcare" => true,
          "works_in_school" => false,
          "work_setting" => "early_years_or_childcare",
          "raw_application_data" => store.except("current_user_id"),
          "referred_by_return_to_teaching_adviser" => "no",
          "accepted_at" => nil,
          "on_submission_trn" => nil,
          "review_status" => nil,
          "reason_for_rejection" => nil,
        })
      end
    end

    context "when teacher catchment is empty" do
      let(:store) do
        {
          "current_user_id" => user.id,
          "course_identifier" => course.identifier,
          "institution_id" => private_childcare_provider.institution.id,
          "lead_provider_id" => lead_provider.id,
          "works_in_childcare" => "yes",
          "works_in_school" => "no",
          "kind_of_nursery" => "private_nursery",
          "teacher_catchment" => nil,
          "teacher_catchment_country" => nil,
          "work_setting" => "early_years_or_childcare",
          "referred_by_return_to_teaching_adviser" => "no",
          "on_submission_trn" => nil,
        }
      end

      it "stores data from store" do
        subject.call

        expect(stable_as_json(user.applications.last)).to match({
          "course_id" => course.id,
          "schedule_id" => nil,
          "ecf_id" => user.applications.last.ecf_id,
          "eligible_for_funding" => false,
          "funded_place" => nil,
          "funding_choice" => nil,
          "funding_eligiblity_status_code" => "not_in_england",
          "kind_of_nursery" => "private_nursery",
          "lead_provider_approval_status" => "pending",
          "participant_outcome_state" => nil,
          "lead_provider_id" => lead_provider.id,
          "notes" => nil,
          "cohort_id" => cohort.id,
          "institution_id" => nil,
          "targeted_support_funding_eligibility" => false,
          "teacher_catchment" => nil,
          "teacher_catchment_country" => nil,
          "teacher_catchment_iso_country_code" => nil,
          "training_status" => nil,
          "ukprn" => nil,
          "number_of_pupils" => 0,
          "primary_establishment" => false,
          "user_id" => user.id,
          "works_in_nursery" => nil,
          "works_in_childcare" => true,
          "works_in_school" => false,
          "work_setting" => "early_years_or_childcare",
          "raw_application_data" => store.except("current_user_id"),
          "referred_by_return_to_teaching_adviser" => "no",
          "accepted_at" => nil,
          "on_submission_trn" => nil,
          "review_status" => nil,
          "reason_for_rejection" => nil,
        })
      end
    end

    context "when teacher catchment is not found" do
      before do
        allow(Sentry).to receive(:capture_message)
      end

      let(:store) do
        {
          "current_user_id" => user.id,
          "course_identifier" => course.identifier,
          "institution_id" => private_childcare_provider.institution.id,
          "lead_provider_id" => lead_provider.id,
          "works_in_childcare" => "yes",
          "works_in_school" => "no",
          "kind_of_nursery" => "private_nursery",
          "teacher_catchment" => "another",
          "teacher_catchment_country" => "wonderland",
          "work_setting" => "early_years_or_childcare",
          "referred_by_return_to_teaching_adviser" => "no",
          "on_submission_trn" => nil,
        }
      end

      it "logs an error" do
        subject.call

        expect(Sentry).to have_received(:capture_message).with("Could not find the ISO3166 alpha3 code for wonderland.", level: :warning)
      end

      it "stores data from store" do
        subject.call

        expect(stable_as_json(user.applications.last)).to match({
          "course_id" => course.id,
          "schedule_id" => nil,
          "ecf_id" => user.applications.last.ecf_id,
          "eligible_for_funding" => false,
          "funded_place" => nil,
          "funding_choice" => nil,
          "funding_eligiblity_status_code" => "not_in_england",
          "kind_of_nursery" => "private_nursery",
          "lead_provider_approval_status" => "pending",
          "participant_outcome_state" => nil,
          "lead_provider_id" => lead_provider.id,
          "notes" => nil,
          "cohort_id" => cohort.id,
          "institution_id" => nil,
          "targeted_support_funding_eligibility" => false,
          "teacher_catchment" => "another",
          "teacher_catchment_country" => "wonderland",
          "teacher_catchment_iso_country_code" => nil,
          "training_status" => nil,
          "ukprn" => nil,
          "number_of_pupils" => 0,
          "primary_establishment" => false,
          "user_id" => user.id,
          "works_in_nursery" => nil,
          "works_in_childcare" => true,
          "works_in_school" => false,
          "work_setting" => "early_years_or_childcare",
          "raw_application_data" => store.except("current_user_id"),
          "referred_by_return_to_teaching_adviser" => "no",
          "accepted_at" => nil,
          "on_submission_trn" => nil,
          "review_status" => nil,
          "reason_for_rejection" => nil,
        })
      end
    end
  end
end
