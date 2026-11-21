require "rails_helper"

RSpec.describe Registration::Steps::ChooseYourProvider do
  subject(:step) { wizard.step(:choose_your_provider) }

  let(:course) { create(:course) }
  let(:course_cohort) { course.course_cohorts.first }
  let(:delivering_provider) { course_cohort.lead_providers.first }
  let(:state_store) { Registration::StateStore.new(repository: DfE::Wizard::Repository::InMemory.new) }
  let(:wizard) { Registration::Wizard.new(course:, current_user: create(:user), current_step: :choose_your_provider, state_store:) }

  before { state_store.write(course_start_date: course_cohort.ecf_id) }

  describe "validations" do
    it "is invalid when blank" do
      expect(step).not_to be_valid
    end

    it "explains what to do when blank" do
      step.valid?

      expect(step.errors[:lead_provider_id]).to include("Choose a provider")
    end

    it "is valid for a provider delivering the course cohort" do
      state_store.write(lead_provider_id: delivering_provider.id.to_s)

      expect(wizard.step(:choose_your_provider)).to be_valid
    end

    it "is invalid for a provider not contracted for the course cohort" do
      state_store.write(lead_provider_id: create(:lead_provider).id.to_s)

      expect(wizard.step(:choose_your_provider)).not_to be_valid
    end

    it "explains what to do for a provider not contracted" do
      state_store.write(lead_provider_id: create(:lead_provider).id.to_s)
      invalid_step = wizard.step(:choose_your_provider)
      invalid_step.valid?

      expect(invalid_step.errors[:lead_provider_id]).to include("Choose a valid provider")
    end
  end

  describe "#options" do
    let(:other_provider) { create(:lead_provider) }

    before { create(:contract_year, course:, lead_provider: other_provider, academic_year: nil) }

    it "enables providers contracted for the course cohort" do
      option = step.options.find { _1.value == delivering_provider.id }

      expect(option.disabled).to be_nil
    end

    it "disables providers of the course not delivering the selected start date" do
      option = step.options.find { _1.value == other_provider.id }

      expect(option.disabled).to be(true)
    end
  end
end
