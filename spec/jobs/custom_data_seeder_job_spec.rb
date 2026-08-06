require "rails_helper"

RSpec.describe CustomDataSeederJob, type: :job do
  subject(:job) do
    described_class.perform_now(
      lead_provider:,
      start_year:,
      nb_cohort:,
      nb_app_per_state:,
    )
  end

  let(:lead_provider) { create(:lead_provider) }
  let(:start_year) { Time.zone.now.year }
  let(:nb_cohort) { 1 }
  let(:nb_app_per_state) { 2 }

  describe "#perform" do
    let(:seeder) { double }

    before do
      allow(ValidTestDataGenerators::APITestScenariosSeeder)
        .to receive(:new)
              .with(lead_provider:, academic_year: start_year)
              .and_return(seeder)
    end

    it "call custom_data method on seeder" do
      expect(seeder).to receive(:custom_data).with(nb_cohort:, nb_app_per_state:)
      job
    end
  end
end
