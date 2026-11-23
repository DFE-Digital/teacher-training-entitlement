require "rails_helper"

RSpec.describe API::V2::ApplicationPresenter do
  subject(:presenter) { described_class.new(application.current_application_lead_provider) }

  let(:application) { create(:application, lead_provider: create(:lead_provider)) }

  it "uses the application ecf_id as id" do
    expect(presenter.id).to eq(application.ecf_id)
  end

  it "reads the email through Application#email" do
    allow(presenter.application).to receive(:email).and_return("work@example.com")

    expect(presenter.email).to eq("work@example.com")
  end

  it "defaults funding choice to dfe" do
    application.update_columns(funding_choice: nil)

    expect(presenter.funding[:choice]).to eq("dfe")
  end

  it "leaves uplift, confirmation reason, role and experience null" do
    expect([presenter.funding[:uplift], presenter.funding[:confirmation_reason], presenter.course[:role], presenter.course[:experience]]).to all(be_nil)
  end

  it "reports funding eligibility from the application" do
    application.update_columns(funding_eligibility: FundingEligibility::FUNDED_ELIGIBILITY_RESULT.to_s)

    expect(presenter.funding.slice(:eligible, :reason)).to eq(eligible: true, reason: nil)
  end

  it "reports the ineligibility reason" do
    application.update_columns(funding_eligibility: FundingEligibility::PREVIOUSLY_FUNDED.to_s)

    expect(presenter.funding.slice(:eligible, :reason)).to eq(eligible: false, reason: "previously_funded")
  end

  [true, false, nil].each do |value|
    it "passes funded_place #{value.inspect} through as funding.confirmed" do
      application.update_columns(funded_place: value)

      expect(presenter.funding[:confirmed]).to eq(value)
    end
  end

  it "returns a nil category without an institution" do
    application.update_columns(institution_id: nil)

    expect(presenter.institution[:category]).to be_nil
  end

  it "has no status reason" do
    expect(presenter.status_reason).to be_nil
  end

  it "has no surveys" do
    expect([presenter.surveys, presenter.survey_ids]).to eq([[], []])
  end

  it "uses the course cohort as contract" do
    expect(presenter.contract_id).to eq(application.course_cohort.ecf_id)
  end

  it "exposes the outcome handed to it" do
    outcome = build(:participant_outcome)

    expect(described_class.new(application.current_application_lead_provider, outcome:).outcome_id).to eq(outcome.ecf_id)
  end

  it "has no outcome by default" do
    expect(presenter.outcome_id).to be_nil
  end

  it "builds one expected declaration per course milestone" do
    expect(presenter.expected_declaration_ids).to eq(
      application.course.milestones.map { |m| "#{application.ecf_id}_#{m.declaration_type}" },
    )
  end
end
