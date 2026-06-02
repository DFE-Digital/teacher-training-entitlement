require "rails_helper"

RSpec.describe Questionnaires::RegistrationSubmitted do
  subject(:form) { described_class.new(wizard:) }

  let(:session) { {} }
  let(:request) { ActionController::TestRequest.new({}, session, ApplicationController) }
  let(:wizard) { RegistrationWizard.new(current_step: :registration_submitted, store: {}, request:, current_user: nil) }

  describe "#previous_step" do
    it { expect(form.previous_step).to be_nil }
  end

  describe "#next_step" do
    it { expect(form.next_step).to be_nil }
  end

  describe "#last_step?" do
    it { expect(form).to be_last_step }
  end

  describe "#requirements_met?" do
    it { expect(form).to be_requirements_met }
  end

  describe "#after_save" do
    it "flags the TRA login to be cleared" do
      expect { form.after_save }.to change { session["clear_tra_login"] }.from(nil).to(true)
    end
  end
end
