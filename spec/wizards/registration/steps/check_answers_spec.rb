require "rails_helper"

RSpec.describe Registration::Steps::CheckAnswers do
  subject(:step) { wizard.step(:check_answers) }

  let(:course) { create(:course) }
  let(:state_store) { Registration::StateStore.new(repository: DfE::Wizard::Repository::InMemory.new) }
  let(:wizard) { Registration::Wizard.new(course:, current_user: create(:user), current_step: :check_answers, state_store:) }

  it { is_expected.to be_valid }

  it "takes no params" do
    expect(described_class.permitted_params).to be_empty
  end
end
