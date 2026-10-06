require "rails_helper"

RSpec.describe Admin::Applications::RevertToPendingController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  subject { response }

  let(:application) { create(:application, :accepted) }

  context "when logged in" do
    before { sign_in_as_admin }

    describe "#new" do
      before { get new_admin_applications_revert_to_pending_path(application) }

      it { is_expected.to have_http_status :success }
      it { is_expected.to have_attributes body: /change the status to pending/i }
    end

    describe "#create" do
      before do
        post admin_applications_revert_to_pending_path(application, params:)
      end

      context "with valid form params" do
        let(:params) { { form: { change_status_to_pending: "yes" } } }

        it { is_expected.to redirect_to admin_application_path(application) }
      end

      context "with invalid form params" do
        let(:params) { { form: { change_status_to_pending: "no" } } }

        it { is_expected.to have_http_status :unprocessable_content }
        it { is_expected.to have_attributes body: /change the status to pending/i }
      end

      context "when the application cannot be reverted" do
        let(:application) { create(:application, :pending) }
        let(:params) { { form: { change_status_to_pending: "yes" } } }

        it { is_expected.to have_http_status :unprocessable_content }
        it { is_expected.to have_attributes body: /change the status to pending/i }
      end
    end
  end

  context "when not logged in" do
    describe "#new" do
      before { get new_admin_applications_revert_to_pending_path(application) }

      it { is_expected.to redirect_to sign_in_path }
    end

    describe "#create" do
      before do
        post admin_applications_revert_to_pending_path(application, params: {})
      end

      it { is_expected.to redirect_to sign_in_path }
    end
  end
end
