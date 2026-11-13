require "rails_helper"

RSpec.describe Cohort, type: :model do
  let(:cohort) { create(:cohort) }

  let(:cohorts) do
    (2024..2026).to_a.shuffle.flat_map do |start_year|
      [5, 8].shuffle.map do |month|
        registration_starts_at = Date.new(start_year, month, 10)
        exist = Cohort.find_by(identifier: Cohort.identifier_for(start_year:, registration_starts_at:))
        exist || create(:cohort, registration_starts_at:)
      end
    end
  end

  subject { cohort }

  describe "validations" do
    it { is_expected.to validate_presence_of(:registration_starts_at) }
    it { is_expected.to validate_presence_of(:start_year) }
    it { is_expected.to allow_value(%w[true false]).for(:funding_cap).with_message("Choose true or false for funding cap") }
    it { is_expected.not_to allow_value(nil).for(:funding_cap).with_message("Choose true or false for funding cap") }
    it { is_expected.to validate_uniqueness_of(:ecf_id).case_insensitive.with_message("ECF ID must be unique").allow_nil }

    it "shows the conflicting cohort start month when the identifier already exists" do
      create(:cohort, registration_starts_at: Date.new(2026, 1, 3))
      duplicate = Cohort.new(
        registration_starts_at: Date.new(2026, 1, 20),
        start_year: 2026,
        description: "Another January 2026 cohort",
        funding_cap: true,
      )

      expect(duplicate).to have_error(:identifier, :taken, "Cohort starting 'Jan 2026' exists already")
    end

    describe "#description" do
      it { is_expected.to validate_presence_of(:description) }
      it { is_expected.to validate_uniqueness_of(:description).case_insensitive }
      it { is_expected.to validate_length_of(:description).is_at_least(5).is_at_most(50) }

      it "defaults to the registration start month on create when blank" do
        cohort = described_class.create!(
          registration_starts_at: Date.new(2028, 6, 1),
          start_year: 2028,
          funding_cap: true,
        )

        expect(cohort.description).to eq("June 2028")
      end

      it "does not overwrite an explicit description on create" do
        cohort = described_class.create!(
          registration_starts_at: Date.new(2028, 7, 1),
          start_year: 2028,
          description: "Custom cohort",
          funding_cap: true,
        )

        expect(cohort.description).to eq("Custom cohort")
      end
    end
  end

  describe ".identifier_for" do
    it "builds the identifier from the start year and registration month" do
      expect(
        described_class.identifier_for(start_year: 2026, registration_starts_at: Date.new(2026, 1, 20)),
      ).to eq("2026-january")
    end

    it "downcases the month name" do
      expect(
        described_class.identifier_for(start_year: 2026, registration_starts_at: Date.new(2026, 4, 1)),
      ).to eq("2026-april")
    end
  end

  describe ".order_by_latest" do
    subject { described_class.where(id: cohorts.map(&:id)).order_by_latest.pluck(:identifier) }

    before { cohorts }

    it { is_expected.to eq %w[2026-august 2026-may 2025-august 2025-may 2024-august 2024-may] }
  end

  describe ".order_by_oldest" do
    subject { described_class.where(id: cohorts.map(&:id)).order_by_oldest.pluck(:identifier) }

    before { cohorts }

    it { is_expected.to eq %w[2024-may 2024-august 2025-may 2025-august 2026-may 2026-august] }
  end

  describe ".prior_to" do
    subject { described_class.where(id: cohorts.map(&:id)).prior_to(cohort_2025).pluck(:identifier) }

    let(:cohort_2025) { cohorts && Cohort.find_by!(identifier: "2025-august") }

    it { is_expected.to match_array %w[2025-may 2024-may 2024-august] }
  end

  describe ".current" do
    it "returns the closest cohort in the past" do
      current_cohort = create(:cohort, registration_starts_at: Date.new(2022, 4, 10))
      _older_cohort = create(:cohort, registration_starts_at: Date.new(2021, 4, 10))
      _future_cohort = create(:cohort, registration_starts_at: Date.new(2023, 4, 10))

      expect(Cohort.current(Date.new(2022, 4, 11))).to eq(current_cohort)
    end

    it "includes the Cohort starting exactly on the current date" do
      current_cohort = create(:cohort, registration_starts_at: Date.new(2022, 4, 10))
      _older_cohort = create(:cohort, registration_starts_at: Date.new(2021, 4, 10))
      _future_cohort = create(:cohort, registration_starts_at: Date.new(2023, 4, 10))

      expect(Cohort.current(Date.new(2022, 4, 10))).to eq(current_cohort)
    end

    context "when there is no cohort for the current year" do
      before { travel_to(10.years.ago) }

      it "raises an error" do
        expect { Cohort.current }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when there are multiple cohorts for the past year" do
      subject { Cohort.current(Date.new(2022, 4, 11)) }

      before { multiple_cohorts }

      let :multiple_cohorts do
        {
          current: create(:cohort, registration_starts_at: Date.new(2022, 4, 10), description: "2022 April"),
          older: create(:cohort, registration_starts_at: Date.new(2022, 1, 10), description: "2022 January"),
          future: create(:cohort, registration_starts_at: Date.new(2023, 4, 10)),
        }
      end

      it { is_expected.to eq(multiple_cohorts[:current]) }
    end
  end

  describe "#name" do
    subject { cohort.name }

    it { is_expected.to eq cohort.description }
  end

  describe "#registration_period" do
    subject(:registration_period) { cohort.registration_period }

    let(:cohort) do
      build(
        :cohort,
        registration_starts_at: Date.new(2026, 9, 1),
        registration_ends_at:,
      )
    end

    context "when registration start and end dates are set" do
      let(:registration_ends_at) { Date.new(2026, 10, 31) }

      it { is_expected.to eq("1 Sep 2026 - 31 Oct 2026") }
    end

    context "when registration end date is blank" do
      let(:registration_ends_at) { nil }

      it { is_expected.to eq("1 Sep 2026 - [no end date]") }
    end
  end
end
