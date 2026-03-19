require "rails_helper"

RSpec.describe Questionnaires::ChoosePrivateChildcareProvider, :npq, type: :model do
  let(:current_step) { :choose_private_childcare_provider }
  let(:store) { { "works_in_childcare" => "yes" } }
  let(:request) { nil }

  let(:wizard) do
    RegistrationWizard.new(current_step:, store:, request:, current_user: create(:user))
  end

  describe "validations" do
    subject { described_class.new(wizard:) }

    let(:private_childcare_provider) { create(:private_childcare_provider) }

    describe "#institution_id" do
      it "can have institution_id as empty string" do
        subject.institution_id = ""
        expect(subject).to be_valid
      end

      it "can have institution_id as 'other'" do
        subject.institution_id = "other"
        expect(subject).to be_valid
      end

      it "can have institution_id as a numeric string" do
        subject.institution_id = private_childcare_provider.institution.id.to_s
        expect(subject).to be_valid
      end

      it "is invalid when the institution_id is non-numeric" do
        subject.institution_id = "PrivateChildcareProvider-123456"
        expect(subject).to be_invalid
        expect(subject.errors[:institution_id]).to be_present
      end

      it "is invalid when the institution_id does not exist" do
        subject.institution_id = "999999999"
        expect(subject).to be_invalid
        expect(subject.errors[:institution_id]).to be_present
      end

      it { is_expected.to validate_length_of(:institution_name).is_at_most(64) }
    end
  end

  describe "#next_step" do
    context "when institution_id is blank" do
      it "is choose_private_childcare_provider" do
        expect(subject.next_step).to be(:choose_private_childcare_provider)
      end
    end

    context "when institution_id is present" do
      before { allow(subject).to receive(:institution_id).and_return("12345") }

      it "is choose_your_npq" do
        expect(subject.next_step).to be(:choose_your_npq)
      end
    end
  end

  describe "#previous_step" do
    it { expect(subject.previous_step).to be(:have_ofsted_urn) }
  end
end
