require "rails_helper"

RSpec.describe "particpant_outcome", :npq do
  describe "create" do
    after { Rake::Task["participant_outcomes:create"].reenable }

    let(:user) { create(:user) }
    let(:lead_provider) { create(:lead_provider) }
    let(:course) { create(:course, :npd_eirt) }
    let(:completion_date) { Date.new(2025, 8, 1).as_json }
    let(:application) { create(:application, :accepted, user:, course:, lead_provider:) }
    let(:declaration) { create(:declaration, :completed, user:, lead_provider:, course:, application:) }
    let(:user_ecf_id) { user.ecf_id }
    let(:lead_provider_ecf_id) { lead_provider.ecf_id }
    let(:state) { nil }

    before { declaration }

    subject(:run_task) do
      Rake::Task["participant_outcomes:create"]
        .invoke(application.id, user_ecf_id, lead_provider_ecf_id, course.identifier, completion_date, state)
    end

    context "when the user does not exist" do
      let(:user_ecf_id) { "non-existent-id" }

      it "raises an error" do
        expect { run_task }.to raise_error(RuntimeError, "User not found: #{user_ecf_id}")
      end
    end

    context "when the lead provider does not exist" do
      let(:lead_provider_ecf_id) { "non-existent-id" }

      it "raises an error" do
        expect { run_task }.to raise_error(RuntimeError, "Lead provider not found: #{lead_provider_ecf_id}")
      end
    end

    context "when there is a validation error" do
      let(:completion_date) { "invalid-date" }

      it "raises an error" do
        expect { run_task }.to raise_error(
          RuntimeError, I18n.t("completion_date.invalid", parameterized_attribute: "completion_date")
        )
      end
    end

    context "when state is not specified" do
      it "creates a passed participant outcome" do
        expect { run_task }.to change { ParticipantOutcome.all.to_a }.from([]).to(
          [an_object_having_attributes(
            declaration_id: declaration.id,
            completion_date: Date.parse(completion_date),
            state: "passed",
          )],
        )
      end
    end

    context "when state is specified" do
      context "when the state is invalid" do
        let(:state) { "invalid_state" }

        it "raises an error" do
          expect { run_task }.to raise_error(RuntimeError, I18n.t("state.inclusion", parameterized_attribute: "state"))
        end
      end

      context "when the state is valid" do
        let(:state) { "failed" }

        it "creates a participant outcome with the specified state" do
          expect { run_task }.to change { ParticipantOutcome.all.to_a }.from([]).to(
            [an_object_having_attributes(
              declaration_id: declaration.id,
              completion_date: Date.parse(completion_date),
              state:,
            )],
          )
        end
      end
    end
  end
end
