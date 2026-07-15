require "rails_helper"

RSpec.describe API::ApplicationSerializer, type: :serializer do
  let(:user) { application.user }
  let(:course) { create(:course, :npd_eirt) }
  let(:cohort) { create(:cohort, :current, course:) }
  let(:institution) { create(:institution, :for_school) }
  let(:application) { create(:application, course:, cohort:, institution:) }
  let(:unassigned) { build(:application_lead_provider, :unassigned) }
  let(:v1_json) { JSON.parse(described_class.render(application, view: :v1, root: "data")) }

  describe "core attributes" do
    subject(:response) { v1_json["data"] }

    it "serializes the `id`" do
      application.ecf_id = "fe1a5280-1b13-4b09-b9c7-e2b01d37e851"

      expect(response["id"]).to eq("fe1a5280-1b13-4b09-b9c7-e2b01d37e851")
    end

    it "serializes the `type`" do
      expect(response["type"]).to eq("application")
    end
  end

  describe "nested attributes" do
    subject(:attributes) { v1_json.dig("data", "attributes") }

    it "serializes the `schedule_identifier`" do
      expect(attributes["schedule_identifier"]).to eq(cohort.identifier)
    end

    it "serializes the `funding_choice`" do
      application.funding_choice = "school"
      expect(attributes["funding_choice"]).to eq(application.funding_choice)
    end

    it "serializes the `works_in_school`" do
      application.works_in_school = true
      expect(attributes["works_in_school"]).to eq(application.works_in_school)
    end

    it "serializes the `email_validated`" do
      expect(attributes["email_validated"]).to be(true)
    end

    it "serializes the `status`" do
      application.status = Application::PENDING
      expect(attributes["status"]).to eq(application.status)
    end

    it "serializes the `eligible_for_funding` (previously funded)" do
      application.eligible_for_funding = true
      expect(attributes["eligible_for_funding"]).to be(true)
    end

    it "serializes the `ineligible_for_funding_reason`" do
      application.funding_eligiblity_status_code = "ineligible_setting"
      expect(attributes["ineligible_for_funding_reason"]).to eq("ineligible_setting")
    end

    it "serializes the `teacher_catchment`" do
      application.teacher_catchment = "england"
      expect(attributes["teacher_catchment"]).to be(true)
    end

    it "serializes the `teacher_catchment_country`" do
      application.teacher_catchment_country = "country"
      expect(attributes["teacher_catchment_country"]).to eq(application.teacher_catchment_country)
    end

    it "serializes the `teacher_catchment_iso_country_code`" do
      application.teacher_catchment_iso_country_code = "iso"
      expect(attributes["teacher_catchment_iso_country_code"]).to eq(application.teacher_catchment_iso_country_code)
    end

    it "serializes the `assigned_at`" do
      application.assignment = application.current_application_lead_provider
      expect(attributes["assigned_at"]).to eq(application.current_application_lead_provider.assigned_at.rfc3339)
    end

    it "serializes the `unassigned_at`" do
      application.assignment = unassigned
      expect(attributes["unassigned_at"]).to eq(unassigned.unassigned_at.rfc3339)
    end

    describe "cohort serialization" do
      it "serializes the `cohort`" do
        expect(attributes["cohort"]).to eq(cohort.start_year.to_s)
      end
    end

    describe "institution serialization" do
      it "serializes the `institution_reference_number`" do
        expect(attributes["institution_reference_number"]).to eq(institution.institution_reference_number)
        expect(attributes["institution_type"]).to eq(institution.institutionable_type.downcase)
      end

      it "serializes the `ukprn`" do
        expect(attributes["ukprn"]).to eq(institution.ukprn)
      end

      context "when `school` is `nil`" do
        let(:application) { create(:application, cohort:, course:, institution: nil) }

        it { expect(attributes["institution_reference_number"]).to be_nil }
        it { expect(attributes["institution_type"]).to be_nil }
        it { expect(attributes["ukprn"]).to be_nil }
      end
    end

    describe "course serialization" do
      it "serializes the `course_identifier`" do
        expect(attributes["course_identifier"]).to eq(course.identifier)
      end
    end

    describe "user serialization" do
      it "serializes the `participant_id`" do
        user.ecf_id = SecureRandom.uuid
        expect(attributes["participant_id"]).to eq(user.ecf_id)
      end

      it "serializes the `email`" do
        user.email = "email@address.com"
        expect(attributes["email"]).to eq(user.email)
      end

      it "serializes the `full_name`" do
        user.full_name = "full name"
        expect(attributes["full_name"]).to eq(user.full_name)
      end

      it "serializes the `teacher_reference_number`" do
        user.trn = "1234567"
        expect(attributes["teacher_reference_number"]).to eq(user.trn)
      end
    end

    describe "timestamp serialization" do
      it "serializes the `created_at`" do
        application.created_at = Time.utc(2023, 7, 1, 12, 0, 0)

        expect(attributes["created_at"]).to eq("2023-07-01T12:00:00Z")
      end

      it "serializes the `updated_at`" do
        user.significantly_updated_at = Time.utc(2023, 7, 2, 11, 0, 0)
        application.updated_at = Time.utc(2023, 7, 2, 12, 0, 0)

        expect(attributes["updated_at"]).to eq("2023-07-02T12:00:00Z")
      end

      context "when the user was updated after the application" do
        it "serializes the `updated_at` as the user's updated_at" do
          application.updated_at = Time.utc(2023, 7, 2, 12, 0, 0)
          user.significantly_updated_at = Time.utc(2024, 7, 2, 12, 0, 0)

          expect(attributes["updated_at"]).to eq("2024-07-02T12:00:00Z")
        end
      end

      describe "reason_for_rejection serialization" do
        let(:application) { create(:application, :rejected, :with_state_change) }

        it "serializes the `reason_for_rejection`" do
          expect(attributes["reason_for_rejection"]).to eq("rejected-by-provider")
        end
      end
    end
  end
end
