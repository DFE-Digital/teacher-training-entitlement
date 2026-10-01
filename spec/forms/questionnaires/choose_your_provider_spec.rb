require "rails_helper"

RSpec.describe Questionnaires::ChooseYourProvider, type: :model do
  let!(:lead_provider) { create(:lead_provider) }
  let!(:course) { create(:course, :npd_eirt, lead_provider:) }
  let(:course_cohort) { course.course_cohorts.first }
  let(:cohort) { course_cohort.cohort }

  describe "validations" do
    let(:current_step) { "choose_your_provider" }
    let(:request) { nil }
    let(:school) { bulid_stubbed(:school) }
    let(:store) { { "course_cohort_ecf_id" => course_cohort.ecf_id } }
    let(:wizard) do
      RegistrationWizard.new(
        current_step:,
        store:,
        request:,
        current_user: create(:user),
      )
    end
    let(:lead_provider_id) { nil }

    before do
      subject.wizard = wizard
    end

    subject { described_class.new(lead_provider_id:) }

    it { is_expected.to validate_presence_of(:lead_provider_id) }

    context "No lead provider" do
      let(:lead_provider_id) { 0 }

      it { is_expected.to have_error(:lead_provider_id) }
    end

    context "With lead provider" do
      let(:lead_provider_id) { lead_provider.id }

      it { is_expected.not_to have_error(:lead_provider_id) }
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
    let(:enabled_providers) { course_cohort.lead_providers.alphabetical.pluck(:id) }

    before do
      form.wizard = RegistrationWizard.new(
        current_step: :choose_your_provider,
        store: { "course_cohort_ecf_id" => course_cohort.ecf_id },
        request: nil,
        current_user: create(:user),
      )
    end

    context "when all course lead_providers deliver the course for this course_cohort" do
      it "returns all provider options" do
        expect(subject.map(&:value)).to eq(enabled_providers)
      end
    end

    context "when some providers are not delivering the course for course_cohort" do
      let(:disabled_providers) { course.lead_providers.pluck(:id) - enabled_providers }

      before do
        course_cohort.course_cohort_providers.first.destroy!
        LeadProvider.find_each do |lead_provider|
          create(:contract_year, :course_details, lead_provider:, course: course_cohort.course)
        end
        course_cohort.course.reload
      end

      it "returns all provider options" do
        actual_enabled_providers = subject.reject(&:disabled).map(&:value)
        actual_disabled_providers = subject.select(&:disabled).map(&:value)

        expect(actual_enabled_providers).to eq(enabled_providers)
        expect(actual_disabled_providers).to eq(disabled_providers)
        expect(subject.map(&:value)).to match_array(enabled_providers + disabled_providers)
      end
    end
  end
end
