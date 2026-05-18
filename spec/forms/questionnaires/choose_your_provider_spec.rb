require "rails_helper"

RSpec.describe Questionnaires::ChooseYourProvider, type: :model do
  let!(:cohort) { create(:cohort, :current) }
  let!(:lead_provider) { create(:lead_provider) }
  let!(:course) { create(:course, :tte_early_years, lead_provider:) }
  let!(:course_cohort) { create(:course_cohort, course:, cohort:, lead_provider:) }

  describe "validations" do
    let(:current_step) { "choose_your_provider" }
    let(:request) { nil }
    let(:school) { bulid_stubbed(:school) }
    let(:store) { {} }
    let(:wizard) do
      RegistrationWizard.new(
        current_step:,
        store:,
        request:,
        current_user: create(:user),
      )
    end

    before do
      subject.wizard = wizard
    end

    it { is_expected.to validate_presence_of(:lead_provider_id) }

    it "lead provider must exist" do
      subject.lead_provider_id = 0
      subject.valid?
      expect(subject.errors[:lead_provider_id]).to be_present
      subject.lead_provider_id = lead_provider.id
      subject.valid?
      expect(subject.errors[:lead_provider_id]).to be_blank
    end

    it "is valid when not chosen option is selected" do
      subject.lead_provider_id = described_class::NOT_CHOSEN
      subject.valid?
      expect(subject.errors[:lead_provider_id]).to be_blank
    end
  end

  describe "#previous_step" do
    subject { described_class.new.previous_step }

    it { is_expected.to eq :course_start_date }
  end

  describe "#next_step" do
    context "when a provider is chosen" do
      subject { described_class.new(lead_provider_id: lead_provider.id).next_step }

      it { is_expected.to eq :teacher_catchment }
    end

    context "when provider is not chosen" do
      subject { described_class.new(lead_provider_id: described_class::NOT_CHOSEN).next_step }

      it { is_expected.to eq :choose_a_tte_and_provider }
    end
  end

  describe ".options" do
    subject { form.options }

    let(:form) { described_class.new }
    let(:expected_providers) { LeadProvider.for(course:).alphabetical }

    before do
      form.wizard = RegistrationWizard.new(
        current_step: :choose_your_provider,
        store: {},
        request: nil,
        current_user: create(:user),
      )
    end

    it "returns all provider options plus the not chosen option" do
      provider_ids = expected_providers.pluck(:id)
      expect(subject.map(&:value)).to eq(provider_ids + [described_class::NOT_CHOSEN])
    end

    it "includes a divider before the not chosen option" do
      not_chosen_option = subject.find { |o| o.value == described_class::NOT_CHOSEN }
      expect(not_chosen_option.divider).to be true
    end
  end

  describe "#not_chosen_provider?" do
    let(:form) { described_class.new }

    context "when lead_provider_id is NOT_CHOSEN" do
      before { form.lead_provider_id = described_class::NOT_CHOSEN }

      it { expect(form.not_chosen_provider?).to be true }
    end

    context "when lead_provider_id is a real provider id" do
      before { form.lead_provider_id = LeadProvider.first.id }

      it { expect(form.not_chosen_provider?).to be false }
    end
  end
end
