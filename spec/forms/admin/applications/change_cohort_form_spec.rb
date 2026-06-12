# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Applications::ChangeCohortForm, type: :model do
  subject(:service) { described_class.new(application:, course_cohort_id:) }

  let(:application) { create(:application, course_cohort:) }
  let(:course_cohort) { create(:course_cohort, cohort: create(:cohort, start_year: 2021)) }
  let(:course) { course_cohort.course }
  let(:new_cohort) { create(:cohort, start_year: 2025) }
  let(:new_course_cohort) { create(:course_cohort, course:, cohort: new_cohort) }
  let(:course_cohort_id) { new_course_cohort.id }

  describe "validation" do
    it { is_expected.to validate_presence_of(:course_cohort_id).with_message "Choose a cohort" }
  end

  describe "#cohort_options" do
    let(:cohort_2022) { create(:cohort, start_year: 2022) }
    let(:cohort_2023) { create(:cohort, start_year: 2023) }
    let(:cohort_2024) { create(:cohort, start_year: 2024) }

    before do
      create(:course_cohort, course:, cohort: cohort_2022)
      create(:course_cohort, course:, cohort: cohort_2023)
    end

    it "includes all cohorts except the application's current cohort" do
      expect(service.course_cohort_options.map(&:id).sort).to eq(course.course_cohorts.map(&:id).excluding(application.course_cohort_id).sort)
    end
  end
end
