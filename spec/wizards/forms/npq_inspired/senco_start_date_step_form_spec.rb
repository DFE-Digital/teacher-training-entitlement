require "rails_helper"

RSpec.describe Forms::NpqInspired::SencoStartDateStepForm do
  subject(:form) do
    described_class.new(
      senco_start_month:,
      senco_start_year:,
    )
  end

  let(:senco_start_month) { 7 }
  let(:senco_start_year) { 2026 }

  it { is_expected.to be_valid }

  it "rejects an invalid month" do
    form.senco_start_month = 13

    expect(form).not_to be_valid
    expect(form.errors[:senco_start_month]).to be_present
  end

  it "rejects a date in the future" do
    travel_to Date.new(2026, 8, 19) do
      form.senco_start_month = 9
      form.senco_start_year = 2026

      expect(form).not_to be_valid
      expect(form.errors[:senco_start_month]).to include("and year must not be in the future")
    end
  end
end
