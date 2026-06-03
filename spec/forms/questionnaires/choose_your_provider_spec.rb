require "rails_helper"

RSpec.describe Questionnaires::ChooseYourProvider, type: :model do
  let!(:cohort) { create(:cohort, :current) }
  let!(:lead_provider) { create(:lead_provider) }
  let!(:course) { create(:course, :npd_eirt, lead_provider:) }

  before { create(:course_cohort, course:, cohort:, lead_provider:) }

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
  end

  describe "#previous_step" do
    subject { described_class.new.previous_step }

    it { is_expected.to eq :course_start_date }
  end

  describe "#next_step" do
    subject { described_class.new.next_step }

    it { is_expected.to eq :teacher_catchment }
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

    it "returns all provider options" do
      expect(subject.map(&:value)).to eq(expected_providers.pluck(:id))
    end
  end
end
