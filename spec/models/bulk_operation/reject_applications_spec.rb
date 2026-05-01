require "rails_helper"

RSpec.describe BulkOperation::RejectApplications do
  let(:application_ecf_ids) { [application.ecf_id] }
  let(:bulk_operation) { create(:reject_applications_bulk_operation, admin: create(:admin)) }
  let(:file) { tempfile(application_ecf_ids.join("\n")) }

  before { bulk_operation.file.attach(file.open) }

  describe "#run!" do
    subject(:run) { bulk_operation.run! }

    context "when the application is already status: rejected" do
      let(:application) { create(:application, :rejected, :with_state_change) }

      it { expect { run }.not_to(change { application.reload.status }) }

      it "saves the result" do
        run
        expect(JSON.parse(bulk_operation.result)[application.ecf_id]).to match(/application has already been rejected/)
      end
    end

    context "when the application is status: pending" do
      let(:application) { create(:application, :pending) }

      it { expect { run }.to(change { application.reload.status }.from(Application::PENDING).to(Application::REJECTED)) }
      it { expect(run[application.ecf_id]).to eq("Changed to rejected") }

      it "stores the reason in state_change" do
        run
        expect(application.reload.reason_for_rejection).to eq("registration-expired")
      end

      it "sets finished_at" do
        subject
        expect(bulk_operation.reload.finished_at).to be_present
      end
    end

    context "when the application does not exist" do
      let(:application_ecf_id) { SecureRandom.uuid }
      let(:application_ecf_ids) { [application_ecf_id] }
      let(:application) { nil }

      it { expect(run[application_ecf_id]).to match(/Not found/) }
    end

    context "when the application ecf_id is not a valid UUID" do
      let(:application_ecf_id) { "invalid-uuid" }
      let(:application_ecf_ids) { [application_ecf_id] }
      let(:application) { nil }

      it { expect(run[application_ecf_id]).to match(/Not found/) }
    end
  end
end
