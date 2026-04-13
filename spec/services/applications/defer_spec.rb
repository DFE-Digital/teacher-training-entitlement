require "rails_helper"

RSpec.describe Applications::Defer, type: :model do
  subject(:service) { described_class.new(application:, reason:, admin_user:) }

  let(:reason) { "other" }
  let(:error_message_path) { "activemodel.errors.models.applications/defer.attributes" }
  let(:admin_user) { nil }

  before { service.call }

  describe "validations" do
    context "when application was superceded" do
      let(:application) { build(:application, :superceded) }

      it { is_expected.to have_error(:application, :application_was_superceded, I18n.t("application.application_was_superceded")) }
    end
  end

  describe "performed by admin user" do
    let(:admin_user) { build(:admin) }

    context "when deferring without a reason" do
      let(:reason) { nil }
      let(:application) { create(:application, :started) }

      it { is_expected.to have_error(:reason, :inclusion) }
    end

    context "when deferring a withdrawn application" do
      let(:application) { create(:application, :withdrawn) }

      it { expect(application.reload.status).to eq(Application::DEFERRED) }
    end

    context "when deferring a deferred application" do
      let(:application) { create(:application, :deferred) }

      it { is_expected.to have_error(:application, :has_already_been_deferred) }
    end

    context "when successfully deferring" do
      let(:application) { create(:application, :started) }

      it do
        expect(service.errors).to be_blank
        expect(application.reload.status).to eq(Application::DEFERRED)
      end
    end
  end

  describe "performed by lead provider" do
    context "when deferring without a reason" do
      let(:reason) { nil }
      let(:application) { create(:application, :started) }

      it { is_expected.to have_error(:reason, :inclusion) }
    end

    context "when deferring a withdrawn application" do
      let(:application) { create(:application, :withdrawn) }

      it { is_expected.to have_error(:application, :not_deferrable) }
    end

    context "when deferring a deferred application" do
      let(:application) { create(:application, :deferred) }

      it { is_expected.to have_error(:application, :has_already_been_deferred) }
    end

    context "when successfully deferring" do
      let(:application) { create(:application, :started) }

      it do
        expect(service.errors).to be_blank
        expect(application.reload.status).to eq(Application::DEFERRED)
      end
    end
  end
end
