# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Applications::ChangeCohortForm, type: :model do
  subject(:service) { described_class.new(application:, cohort_id:) }

  let(:course) { create(:course) }
  let(:cohort) { create(:cohort, start_year: 2021, course:) }
  let(:application) { create(:application, course:, cohort:) }
  let(:new_cohort) { create(:cohort, start_year: 2025, course:) }
  let(:cohort_id) { new_cohort.id }

  describe "validation" do
    it { is_expected.to validate_presence_of(:cohort_id).with_message "Choose a cohort" }
  end

  describe "#cohort_options" do
    let(:cohort_2022) { create(:cohort, start_year: 2022, course:) }
    let(:cohort_2023) { create(:cohort, start_year: 2023, course:) }
    let(:cohort_2024) { create(:cohort, start_year: 2024) }

    before do
      cohort_2022
      cohort_2023
      cohort_2024
    end

    it "includes all cohorts except the application's current cohort" do
      expect(service.cohort_options.map(&:id).sort).to eq(course.cohorts.map(&:id).excluding(application.cohort_id).sort)
    end
  end
end
