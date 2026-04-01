require "rails_helper"

RSpec.describe Applications::Defer, type: :model do
  subject(:service) { described_class.new(application:, reason:, admin_user: create(:admin)) }

  let(:application) { create(:application, :accepted, :with_declaration) }
  let(:reason) { nil }
  let(:error_message_path) { "activemodel.errors.models.applications/defer.attributes" }

  before { service.call }

  context "when deferring without a reason" do
    let(:reason) { nil }

    it do
      expect(service.errors).not_to be_blank
      expect(service.errors[:reason])
        .to include(I18n.t("#{error_message_path}.reason.missing_reason"))
    end
  end

  context "when deferring a withdrawn application" do
    let(:application) { create(:application, :withdrawn, :with_declaration) }

    it do
      expect(service.errors).not_to be_blank
      expect(service.errors[:base])
        .to include(I18n.t("#{error_message_path}.base.already_withdrawn"))
    end
  end

  context "when deferring a deferred application" do
    let(:reason) { nil }
    let(:application) { create(:application, :deferred, :with_declaration) }

    it do
      expect(service.errors).not_to be_blank
      expect(service.errors[:base])
        .to include(I18n.t("#{error_message_path}.base.already_deferred"))
    end
  end

  context "when successfully deferring" do
    let(:reason) { "other" }
    let(:application) { create(:application, :accepted, :with_declaration) }

    it do
      expect(service.errors).to be_blank
      expect(application.reload.status).to eq(Application::DEFERRED)
    end
  end
end
