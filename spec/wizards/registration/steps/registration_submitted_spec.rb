require "rails_helper"

RSpec.describe Registration::Steps::RegistrationSubmitted do
  subject(:step) { wizard.step(:registration_submitted) }

  let(:course) { create(:course) }
  let(:user) { create(:user) }
  let(:state_store) { Registration::StateStore.new(repository: DfE::Wizard::Repository::InMemory.new) }
  let(:wizard) { Registration::Wizard.new(course:, current_user: user, current_step: :registration_submitted, state_store:) }

  it { is_expected.not_to be_valid }

  context "when the teacher submitted an application" do
    before { state_store.write(submitted_application_id: create(:application, user:).id) }

    it { is_expected.to be_valid }
  end

  context "when the recorded application belongs to another teacher" do
    before { state_store.write(submitted_application_id: create(:application).id) }

    it { is_expected.not_to be_valid }
  end
end
