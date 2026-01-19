require "rails_helper"

RSpec.describe Questionnaires::ChooseYourProvider, type: :model do
  describe "validations" do
    let(:current_step) { "choose_your_provider" }
    let(:request) { nil }
    let(:course) { build_stubbed(:course, :tte_early_years) }
    let(:school) { bulid_stubbed(:school) }
    let(:store) do
      {
        "course_identifier" => course.identifier,
      }
    end
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

      subject.lead_provider_id = LeadProvider.first.id
      subject.valid?
      expect(subject.errors[:lead_provider_id]).to be_blank
    end
  end

  describe "#previous_step" do
    subject { described_class.new.previous_step }

    it { is_expected.to eq :choose_your_course }
  end

  describe "#next_step" do
    subject { described_class.new.next_step }

    it { is_expected.to eq :teacher_catchment }
  end

  describe ".options" do
    subject { form.options }

    let(:form) { described_class.new }
    let(:course) { build_stubbed(:course, :tte_early_years) }
    let(:store) do
      {
        "course_identifier" => course_identifier,
      }
    end
    let(:course_identifier) { course.identifier }
    let(:expected_providers) { LeadProvider.all }

    before do
      form.wizard = RegistrationWizard.new(
        current_step: :choose_your_provider,
        store:,
        request: nil,
        current_user: create(:user),
      )
    end

    it "returns all options" do
      expect(subject.map(&:value).sort).to eq(expected_providers.pluck(:id).sort)
    end
  end
end
