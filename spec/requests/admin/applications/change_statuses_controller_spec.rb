# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Applications::ChangeStatusesController, :ecf_api_disabled, type: :request do
  include Helpers::NPQSeparationAdminLogin

  subject { response }

  let :application do
    create(:application, :accepted).tap do |application|
      create(:declaration, application:)
    end
  end

  context "when logged in" do
    before { sign_in_as_admin }

    describe "#new" do
      before do
        get new_admin_applications_change_status_path(application)
      end

      it { is_expected.to have_http_status :success }
      it { is_expected.to have_attributes body: /Change.* status/i }
    end

    describe "#create" do
      before do
        post admin_applications_change_status_path(application, params:)
      end

      context "with valid update" do
        let :params do
          {
            form: {
              status: :withdrawn,
              reason: Admin::Applications::ChangeStatusForm::REASON_OPTIONS["withdrawn"].first,
            },
          }
        end

        it { is_expected.to redirect_to admin_application_path(application) }
      end

      context "with invalid update" do
        let(:params) { { change_status: { status: "unexpected" } } }

        it { is_expected.to have_http_status :unprocessable_content }
        it { is_expected.to have_attributes body: /Change.* status/i }
      end
    end
  end

  context "when not logged in" do
    describe "#edit" do
      before { get new_admin_applications_change_status_path(application) }

      it { is_expected.to redirect_to sign_in_path }
    end

    describe "#update" do
      before do
        post admin_applications_change_status_path(application, params: {})
      end

      it { is_expected.to redirect_to sign_in_path }
    end
  end
end
