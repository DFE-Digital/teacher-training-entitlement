require "rails_helper"

RSpec.describe Participants::Resume, type: :model do
  subject(:service) { described_class.new(application:) }

  let(:application) { create(:application, :accepted, :with_declaration) }
  let(:reason) { nil }
  let(:error_message_path) { "activemodel.errors.models.participants/resume.attributes" }

  before { service.call }

  context "when resuming an active application" do
    let(:application) { create(:application, :active, :with_declaration) }

    it do
      expect(service.errors).not_to be_blank
      expect(service.errors[:base])
        .to include(I18n.t("#{error_message_path}.base.already_active"))
    end
  end

  context "when successfully resuming" do
    let(:reason) { "other" }
    let(:application) { create(:application, :deferred, :with_declaration) }

    it do
      expect(service.errors).to be_blank
      expect(application.reload.training_status).to eq(Participants::Strategy::ACTIVE)
    end
  end
end
