require "rails_helper"

RSpec.describe Applications::Withdraw, type: :model do
  subject(:service) { described_class.new(application:, reason:, admin_user: build(:admin)) }

  let(:application) { create(:application, :accepted, :with_declaration) }
  let(:reason) { nil }
  let(:error_message_path) { "activemodel.errors.models.applications/withdraw.attributes" }

  before { service.call }

  context "when withdrawing without a reason" do
    let(:reason) { nil }

    it do
      expect(service.errors).not_to be_blank
      expect(service.errors[:reason])
        .to include(I18n.t("#{error_message_path}.reason.missing_reason"))
    end
  end

  context "when withdrawing a withdrawn application" do
    let(:application) { create(:application, :withdrawn, :with_declaration) }

    it do
      expect(service.errors).not_to be_blank
      expect(service.errors[:base]).not_to be_blank
      expect(service.errors[:base])
        .to include(I18n.t("#{error_message_path}.base.already_withdrawn"))
    end
  end

  context "when successfully withdrawing" do
    let(:reason) { "other" }
    let(:application) { create(:application, :accepted, :with_declaration) }

    it do
      expect(service.errors).to be_blank
      expect(application.reload.status).to eq(Application::WITHDRAWN)
    end
  end

  context "when application was superceded" do
    let(:application) { create(:application, :superceded) }

    before { subject.call }

    it do
      expect(subject).to have_error(:application, :application_was_superceded, I18n.t("application.application_was_superceded"))
    end
  end
end
