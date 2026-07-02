# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples "leadership and specialist #schedule" do
  subject { described_class.new(cohort:, schedule_date: Date.current).schedule }

  before { travel_to(date) }

  let(:date) { Date.new(2025, 6, 1) }

  context "when the course is in the autumn schedule for the 2025 cohort" do
    let!(:autumn_schedule) { create(:schedule, autumn_schedule_identifier, cohort:) }
    let(:cohort) { create(:cohort, registration_starts_at: Date.new(2025, 4, 1)) }

    context "when at the start of the autumn registration window" do
      let(:date) { Date.new(2025, 9, 8) }

      it { is_expected.to eq(autumn_schedule) }
    end

    context "when at the end of the autumn registration window" do
      let(:date) { Date.new(2026, 1, 31) }

      it { is_expected.to eq(autumn_schedule) }
    end
  end

  context "when the course is in the spring schedule for the 2025 cohort" do
    let!(:spring_schedule) { create(:schedule, spring_schedule_identifier, cohort:) }
    let(:cohort) { create(:cohort, registration_starts_at: Date.new(2025, 4, 1)) }

    it { is_expected.to eq(spring_schedule) }
  end

  context "when the course is only in the autumn schedule (like the 2024 cohort)" do
    let!(:autumn_schedule) { create(:schedule, autumn_schedule_identifier, cohort:) }
    let(:cohort) { create(:cohort, registration_starts_at: Date.new(2024, 4, 1)) }

    it { is_expected.to eq(autumn_schedule) }
  end

  context "when course is in both autumn and spring schedules (like 2021-2023 cohorts)" do
    let!(:spring_schedule) { create(:schedule, spring_schedule_identifier, cohort:) }
    let!(:autumn_schedule) { create(:schedule, autumn_schedule_identifier, cohort:) }
    let(:cohort) { create(:cohort, registration_starts_at: Date.new(2023, 4, 1)) }

    context "when date is between 1st January and 2nd April" do
      before { travel_to(Date.new(2025, 4, 2)) }

      it { is_expected.to eq(spring_schedule) }
    end

    context "when date is between 26th December and 31st December" do
      before { travel_to(Date.new(2025, 12, 31)) }

      it { is_expected.to eq(spring_schedule) }
    end

    context "when date is between 3rd April and 25th December" do
      before { travel_to(Date.new(2025, 12, 25)) }

      it { is_expected.to eq(autumn_schedule) }
    end
  end
end
