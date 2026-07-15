require "rails_helper"

RSpec.describe API::ParticipantSerializer, type: :serializer do
  let(:lead_provider) { create(:lead_provider) }
  let(:course) { application.course }
  let(:school) { application.school }
  let(:participant_id_change) { application.participant_id_changes.last }
  let(:cohort) { application.cohort }
  let(:application) { create(:application, :accepted, :with_state_change, :eligible_for_funded_place, :with_participant_id_change, lead_provider:, funded_place: true) }
  let(:participant) { application.user }

  describe "core attributes" do
    subject(:response) { JSON.parse(described_class.render(participant, lead_provider:)) }

    it "serializes the `id`" do
      participant.ecf_id = "fe1a5280-1b13-4b09-b9c7-e2b01d37e851"

      expect(response["id"]).to eq("fe1a5280-1b13-4b09-b9c7-e2b01d37e851")
    end

    it "serializes the `type`" do
      response = JSON.parse(described_class.render(participant))

      expect(response["type"]).to eq("participant")
    end
  end

  describe "nested attributes" do
    context "when serializing the `v1` view" do
      subject(:attributes) { JSON.parse(described_class.render(participant, lead_provider:, view: :v1))["attributes"] }

      it "serializes the `full_name`" do
        expect(attributes["full_name"]).to eq(participant.full_name)
      end

      it "serializes the `teacher_reference_number`" do
        expect(attributes["teacher_reference_number"]).to eq(participant.trn)
      end

      context "when serializing `updated_at`" do
        let(:old_datetime) { Time.utc(2023, 5, 5, 5, 0, 0) }
        let(:latest_datetime) { Time.utc(2024, 8, 8, 8, 0, 0) }

        context "when participant is the latest" do
          it "serializes the `updated_at`" do
            application.update!(updated_at: old_datetime)
            participant_id_change.update!(updated_at: old_datetime)
            participant.update!(significantly_updated_at: latest_datetime)

            expect(attributes["updated_at"]).to eq(latest_datetime.rfc3339)
          end
        end

        context "when application is the latest" do
          it "returns application's `updated_at`" do
            application.update!(updated_at: latest_datetime)
            participant_id_change.update!(updated_at: old_datetime)
            participant.update!(significantly_updated_at: old_datetime)

            expect(attributes["updated_at"]).to eq(latest_datetime.rfc3339)
          end
        end

        context "when participant_id_change is the latest" do
          it "returns participant_id_change's `updated_at`" do
            application.update!(updated_at: old_datetime)
            participant_id_change.update!(updated_at: latest_datetime)
            participant.update!(significantly_updated_at: old_datetime)

            expect(attributes["updated_at"]).to eq(latest_datetime.rfc3339)
          end
        end
      end

      it "serializes the `enrolments`", :freeze_time do
        accepted_event = application.state_changes.find_by(event: Application::ACCEPTED)
        expect(attributes["enrolments"]).to eq([
          {
            email: participant.email,
            course_identifier: application.course.identifier,
            schedule_identifier: application.cohort.identifier,
            cohort: application.cohort.start_year.to_s,
            application_id: application.ecf_id,
            eligible_for_funding: application.eligible_for_funding,
            status: application.status,
            school_urn: application.school.urn,
            withdrawal: nil,
            deferral: nil,
            created_at: accepted_event.created_at.rfc3339,
            funded_place: application.funded_place,
          }.stringify_keys,
        ])
      end

      context "when application has been withdrawn" do
        let(:application) { create(:application, :withdrawn, :with_accepted_event, :eligible_for_funded_place, lead_provider:) }

        let(:withdrawal) { application.state_changes.where(event: Application::WITHDRAWN).first }
        let(:accepted) { application.state_changes.where(event: Application::ACCEPTED).first }

        it "serializes the `enrolments`" do
          expect(attributes["enrolments"]).to eq([
            {
              email: participant.email,
              course_identifier: application.course.identifier,
              schedule_identifier: application.cohort.identifier,
              cohort: application.cohort.start_year.to_s,
              application_id: application.ecf_id,
              eligible_for_funding: application.eligible_for_funding,
              status: application.status,
              school_urn: application.school.urn,
              withdrawal: {
                reason: withdrawal.reason,
                date: withdrawal.created_at.rfc3339,
              },
              deferral: nil,
              created_at: accepted.created_at.rfc3339,
              funded_place: application.funded_place,
            }.deep_stringify_keys,
          ])
        end

        context "when withdrawn state change is missing lead provider" do
          before { withdrawal.update_columns(lead_provider_id: nil) }

          it do
            expect(attributes["enrolments"]).not_to be_nil
          end
        end
      end

      context "when application has been deferred" do
        let(:application) { create(:application, :with_declaration, :deferred, :with_accepted_event, :eligible_for_funded_place, lead_provider:) }
        let(:deferral) { application.state_changes.where(event: Application::DEFERRED).first }
        let(:accepted) { application.state_changes.where(event: Application::ACCEPTED).first }

        it "serializes the `enrolments`" do
          expect(attributes["enrolments"]).to eq([
            {
              email: participant.email,
              course_identifier: application.course.identifier,
              schedule_identifier: application.cohort.identifier,
              cohort: application.cohort.start_year.to_s,
              application_id: application.ecf_id,
              eligible_for_funding: application.eligible_for_funding,
              status: application.status,
              school_urn: application.school.urn,
              withdrawal: nil,
              deferral: {
                reason: deferral.reason,
                date: deferral.created_at.rfc3339,
              },
              created_at: accepted.created_at.rfc3339,
              funded_place: application.funded_place,
            }.deep_stringify_keys,
          ])
        end

        context "when withdrawn state change is missing lead provider" do
          before { deferral.update_columns(lead_provider_id: nil) }

          it do
            expect(attributes["enrolments"]).not_to be_nil
          end
        end
      end

      context "when application has been accepted" do
        let(:application) { create(:application, :with_declaration, :accepted, :with_accepted_event, :eligible_for_funded_place, lead_provider:) }
        let(:accepted) { application.state_changes.where(event: Application::ACCEPTED).first }

        context "when accepted state change is missing lead provider" do
          before { accepted.update_columns(lead_provider_id: nil) }

          it do
            expect(attributes["enrolments"]).not_to be_nil
          end
        end
      end

      it "serializes the `participant_id_changes`" do
        expect(attributes["participant_id_changes"]).to eq([
          {
            from_participant_id: participant.participant_id_changes.last.from_participant_id,
            to_participant_id: participant.participant_id_changes.last.to_participant_id,
            changed_at: participant.participant_id_changes.last.created_at.rfc3339,
          }.stringify_keys,
        ])
      end

      context "when there're multiple application with different lead provider approval states" do
        before { create(:application, :for_cohort_starting_on, lead_provider:, user: participant, registration_starts_at: Date.new(2021, 4, 1)) }

        it "serializes only accepted `enrolments`" do
          expect(attributes["enrolments"].size).to eq(1)
          expect(attributes["enrolments"][0]["application_id"]).to eq(application.ecf_id)
        end
      end
    end
  end
end
