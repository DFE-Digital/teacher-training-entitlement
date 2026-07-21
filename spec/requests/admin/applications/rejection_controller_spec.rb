# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Applications::RejectionController, :ecf_api_disabled, type: :request do
  include Helpers::NPQSeparationAdminLogin

  subject { response }

  context "when logged in" do
    before { sign_in_as_admin }

    describe "#update" do
      before { patch admin_applications_reject_path(application) }

      context "when application in rejectable state" do
        let(:application) { create(:application, :pending) }

        it { is_expected.to redirect_to admin_application_path(application) }
        it { expect(application.reload.status).to eq("rejected") }
      end

      context "when application is not rejectable" do
        let(:application) { create(:application, :accepted) }

        it { is_expected.to have_http_status :unprocessable_content }
        it { expect(application.reload.status).to eq("accepted") }
      end
    end
  end
end
