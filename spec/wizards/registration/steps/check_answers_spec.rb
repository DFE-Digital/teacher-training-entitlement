require "rails_helper"

RSpec.describe Registration::Steps::CheckAnswers do
  subject(:step) { wizard.step(:check_answers) }

  let(:course) { create(:course) }
  let(:state_store) { Registration::StateStore.new(repository: DfE::Wizard::Repository::InMemory.new) }
  let(:wizard) { Registration::Wizard.new(course:, current_user: create(:user), current_step: :check_answers, state_store:) }

  it { is_expected.not_to be_valid }

  it "is valid once the answers were submitted" do
    state_store.write(submitted: true)

    expect(wizard.step(:check_answers)).to be_valid
  end
end
