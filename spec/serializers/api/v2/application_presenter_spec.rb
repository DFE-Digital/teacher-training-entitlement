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

  it "reports uplift eligibility from the application" do
    allow(presenter.application).to receive(:funding_uplift_eligible?).and_return(true)

    expect(presenter.funding[:uplift]).to be(true)
  end

  it "leaves confirmation reason, role and experience null" do
    expect([presenter.funding[:confirmation_reason], presenter.course[:role], presenter.course[:experience]]).to all(be_nil)
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

  it "uses the application status for the current assignment" do
    expect(presenter.status).to eq(application.status)
  end

  it "reads as reassigned for a previous assignment" do
    previous = application.current_application_lead_provider
    application.change_provider!(to: create(:lead_provider))

    expect(described_class.new(previous.reload).status).to eq(Application::REASSIGNED)
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

  it "builds one expected declaration per course milestone, in milestone order" do
    course = application.course
    course.milestones.delete_all
    { "retained-1" => 3, "completed" => 6, "started" => 0 }.each do |declaration_type, offset|
      create(:milestone, course:, declaration_type:, acceptance_window_start_offset: offset)
    end
    unordered = course.milestones.reload.sort_by(&:declaration_sort_order).reverse
    allow(presenter.contract.course).to receive(:milestones).and_return(unordered)

    expect(presenter.expected_declaration_ids).to eq(
      %w[started retained-1 completed].map { |type| "#{application.ecf_id}_#{type}" },
    )
  end
end
