require "rails_helper"

RSpec.describe API::V2::TrainingPresenter do
  subject(:presenter) { described_class.new(application.current_application_lead_provider) }

  let(:application) { create(:application, lead_provider: create(:lead_provider)) }

  it "defaults funding choice to dfe" do
    application.update!(funding_choice: nil)

    expect(presenter.funding[:choice]).to eq("dfe")
  end

  it "leaves uplift, role and experience null" do
    expect([presenter.funding[:uplift], presenter.course[:role], presenter.course[:experience]]).to all(be_nil)
  end

  [true, false, nil].each do |value|
    it "passes funded_place #{value.inspect} through as funding.confirmed" do
      application.update_columns(funded_place: value)

      expect(presenter.funding[:confirmed]).to eq(value)
    end
  end

  it "returns a nil institution_type without an institution" do
    application.update_columns(institution_id: nil)

    expect(presenter.institution_details[:institution_type]).to be_nil
  end

  it "has no status reason" do
    expect(presenter.status_reason).to be_nil
  end

  it "has no surveys" do
    expect(presenter.survey_ids).to eq([])
  end

  it "exposes the outcome handed to it" do
    outcome = build(:participant_outcome)

    expect(described_class.new(application.current_application_lead_provider, outcome:).outcome_id).to eq(outcome.ecf_id)
  end

  it "has no outcome by default" do
    expect(presenter.outcome_id).to be_nil
  end
end
