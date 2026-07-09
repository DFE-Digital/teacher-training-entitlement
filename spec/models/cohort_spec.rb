require "rails_helper"

RSpec.describe Cohort, type: :model do
  let(:cohort) { create(:cohort) }

  let(:cohorts) do
    (2024..2026).to_a.shuffle.flat_map do |start_year|
      [5, 8].shuffle.map do |month|
        registration_starts_at = Date.new(start_year, month, 10)
        exist = Cohort.find_by(identifier: registration_starts_at.strftime("%Y-%B"))
        exist || create(:cohort, start_year:, registration_starts_at:)
      end
    end
  end

  subject { cohort }

  describe "relationships" do
    it { is_expected.to belong_to(:course).optional }
    it { is_expected.to have_many(:declarations).dependent(:restrict_with_exception) }
    it { is_expected.to have_many(:statements).dependent(:restrict_with_exception) }
    it { is_expected.to have_many(:delivery_partnerships) }
    it { is_expected.to have_many(:cohort_providers).dependent(:destroy) }
    it { is_expected.to have_many(:lead_providers).through(:cohort_providers) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:registration_starts_at) }
    it { is_expected.to validate_presence_of(:training_starts_at) }
    it { is_expected.to validate_presence_of(:training_ends_at) }
    it { is_expected.to allow_value(%w[true false]).for(:funding_cap).with_message("Choose true or false for funding cap") }
    it { is_expected.not_to allow_value(nil).for(:funding_cap).with_message("Choose true or false for funding cap") }
    it { is_expected.to validate_uniqueness_of(:ecf_id).case_insensitive.with_message("ECF ID must be unique").allow_nil }

    describe "start_year" do
      it "is set from the registration start date" do
        cohort = Cohort.new(registration_starts_at: Date.new(2023, 4, 10))

        cohort.valid?
        expect(cohort.start_year).to eq(2023)
      end
    end

    describe "#description" do
      it { is_expected.to validate_presence_of(:description) }
      it { is_expected.to validate_uniqueness_of(:description).case_insensitive }
      it { is_expected.to validate_length_of(:description).is_at_least(5).is_at_most(50) }
    end

    describe "#identifier" do
      it "adds a helpful error when another cohort has the same registration start month" do
        registration_starts_at = Date.new(2029, 12, 1)
        create(:cohort, registration_starts_at:)

        duplicate = described_class.new(
          description: "Duplicate cohort",
          registration_starts_at:,
          registration_ends_at: registration_starts_at + 2.months,
          training_starts_at: registration_starts_at + 3.months,
          training_ends_at: registration_starts_at + 9.months,
          funding_cap: true,
        )

        expect(duplicate).to have_error(:identifier, :taken, "Cohort starting 'Dec 2029' exists already")
      end
    end

    describe "changing funding_cap when there are applications" do
      before do
        create(:application, cohort: cohort)
      end

      context "when the funding cap is true" do
        let(:cohort) { create(:cohort, :with_funding_cap) }

        it "does not allow changing the funding_cap" do
          cohort.funding_cap = false
          expect(cohort).to have_error(:funding_cap, "Cannot change funding_cap when there are existing applications for this cohort")
        end
      end

      context "when the funding cap is false" do
        let(:cohort) { create(:cohort, :without_funding_cap) }

        it "does not allow changing the funding_cap" do
          cohort.funding_cap = true
          expect(cohort).to have_error(:funding_cap, "Cannot change funding_cap when there are existing applications for this cohort")
        end
      end
    end
  end

  describe ".order_by_latest" do
    subject { described_class.where(id: cohorts.map(&:id)).order_by_latest.pluck(:identifier) }

    before { cohorts }

    it { is_expected.to eq %w[2026-August 2026-May 2025-August 2025-May 2024-August 2024-May] }
  end

  describe ".order_by_oldest" do
    subject { described_class.where(id: cohorts.map(&:id)).order_by_oldest.pluck(:identifier) }

    before { cohorts }

    it { is_expected.to eq %w[2024-May 2024-August 2025-May 2025-August 2026-May 2026-August] }
  end

  describe ".prior_to" do
    subject { described_class.where(id: cohorts.map(&:id)).prior_to(cohort_2025).pluck(:identifier) }

    let(:cohort_2025) { cohorts && Cohort.find_by!(identifier: "2025-August") }

    it { is_expected.to match_array %w[2025-May 2024-May 2024-August] }
  end

  describe ".current" do
    it "returns the closest cohort in the past" do
      current_cohort = create(:cohort, start_year: 2022, registration_starts_at: Date.new(2022, 4, 10))
      _older_cohort = create(:cohort, start_year: 2021, registration_starts_at: Date.new(2021, 4, 10))
      _future_cohort = create(:cohort, start_year: 2023, registration_starts_at: Date.new(2023, 4, 10))

      expect(Cohort.current(Date.new(2022, 4, 11))).to eq(current_cohort)
    end

    it "includes the Cohort starting exactly on the current date" do
      current_cohort = create(:cohort, start_year: 2022, registration_starts_at: Date.new(2022, 4, 10))
      _older_cohort = create(:cohort, start_year: 2021, registration_starts_at: Date.new(2021, 4, 10))
      _future_cohort = create(:cohort, start_year: 2023, registration_starts_at: Date.new(2023, 4, 10))

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
          current: create(:cohort, start_year: 2022, registration_starts_at: Date.new(2022, 4, 10), description: "2022 April"),
          older: create(:cohort, start_year: 2022, registration_starts_at: Date.new(2022, 1, 10), description: "2022 January"),
          future: create(:cohort, start_year: 2023, registration_starts_at: Date.new(2023, 4, 10)),
        }
      end

      it { is_expected.to eq(multiple_cohorts[:current]) }
    end
  end

  describe "#name" do
    subject { cohort.name }

    it { is_expected.to eq cohort.description }
  end
end
