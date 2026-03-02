# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Applications::ChangeCohortForm, type: :model do
  subject(:service) { described_class.new(id: application.id, cohort_id:) }

  let(:application) { create(:application, cohort: cohort_2021) }
  let(:cohort_2021) { create(:cohort, start_year: 2021) }
  let(:new_cohort) { create(:cohort, start_year: 2025) }
  let(:cohort_id) { new_cohort.id }

  describe "validation" do
    it { is_expected.to validate_presence_of(:cohort_id).with_message "Choose a cohort" }
  end

  describe "#cohort_options" do
    let(:cohort_2022) { create(:cohort, start_year: 2022) }
    let(:cohort_2023) { create(:cohort, start_year: 2023) }
    let(:cohort_2024) { create(:cohort, start_year: 2024) }
    let(:schedule_2021) { create(:schedule, :tte_reception_autumn, cohort: cohort_2021) }

    before do
      create(:schedule, :tte_reception_autumn, cohort: new_cohort)
      create(:schedule, :tte_reception_autumn, cohort: cohort_2022)
      create(:schedule, :tte_reception_spring, cohort: cohort_2022)
      create(:schedule, :npq_specialist_autumn, cohort: cohort_2022)
      create(:schedule, :tte_reception_autumn, cohort: cohort_2023)
      create(:schedule, :tte_reception_spring, cohort: cohort_2023)
    end

    context "when the application is in a schedule" do
      let(:application) { create(:application, cohort: cohort_2021, schedule: schedule_2021) }

      it "includes all cohorts with schedules for the course group excluding the application's current cohort" do
        expect(service.cohort_options).to contain_exactly(cohort_2022, cohort_2023, new_cohort)
      end
    end

    context "when the application is not in a schedule" do
      it "includes all cohorts except the application's current cohort" do
        expect(service.cohort_options).to eq [cohort_2022, cohort_2023, cohort_2024, new_cohort]
      end
    end
  end
end
