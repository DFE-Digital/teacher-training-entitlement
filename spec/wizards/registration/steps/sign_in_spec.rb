require "rails_helper"

RSpec.describe Registration::Steps::SignIn do
  subject(:step) { wizard.current_step }

  let(:wizard) do
    Registration::Wizard.new(
      course: create(:course),
      current_user: user,
      current_step: :sign_in,
      state_store: Registration::StateStore.new(repository: DfE::Wizard::Repository::InMemory.new),
    )
  end

  context "when the teacher is signed in" do
    let(:user) { create(:user) }

    it { is_expected.to be_valid }
  end

  context "when the teacher is signed out" do
    let(:user) { nil }

    it { is_expected.not_to be_valid }

    it "asks the teacher to sign in" do
      step.valid?

      expect(step.errors[:base]).to include("You need to sign in to continue.")
    end
  end
end
