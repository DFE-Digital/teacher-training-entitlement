require "rails_helper"

RSpec.describe Registrations::ApplicationCreation do
  subject(:service) { described_class.new(wizard_step:) }

  let(:user) { create(:user, ecf_id: nil) }
  let(:lead_provider) { create(:lead_provider) }
  let(:course_cohort) do
    create(:course_cohort, course: Course.reception, cohort: create(:cohort, :current), lead_provider:)
  end
  let(:institution) { create(:institution) }
  let(:store_data) do
    {
      "course_cohort_ecf_id" => course_cohort.ecf_id,
      "lead_provider_id" => lead_provider.id,
      "institution_id" => institution.id,
      "teacher_catchment" => Institution::ENGLAND_SUBDIVISION_CODE,
      "work_setting" => Institution::STATE_FUNDED_INSTITUTION,
      "funding" => "school",
      "funding_eligibility_result" => "funded",
      "generated_confirmation_code" => "confirmation-code",
      "check_your_answers_and_submit" => "should not be saved",
      "current_user_id" => user.id,
      "answer" => "value",
    }
  end
  let(:state_store) { double(read: store_data, write: nil) }
  let(:wizard) { double(current_user: user, state_store:, data: { steps: { start: store_data } }) }
  let(:wizard_step) { double(wizard:) }

  before do
    allow(state_store).to receive(:write)
    allow(Emails::SendApplicationSubmissionEmailJob).to receive(:perform_later)

    subject.call
  end

  it "creates the application from the selected registration data" do
    application = user.applications.sole

    expect(application).to have_attributes(
      course_cohort:,
      institution:,
      funding_eligibility: "funded",
      funding_choice: nil,
      status: Application::PENDING,
      registration_data: hash_including("answer" => "value"),
    )
    expect(application.registration_data).to include(
      "teacher_catchment" => Institution::ENGLAND_SUBDIVISION_CODE,
      "work_setting" => Institution::STATE_FUNDED_INSTITUTION,
    )
    expect(application.registration_data).not_to include(
      "generated_confirmation_code",
      "current_user",
      "current_user_id",
      "funding_eligibility_result",
      "check_your_answers_and_submit",
    )
    expect(application.application_lead_providers.sole).to have_attributes(
      lead_provider:,
      current: true,
      assigned_at: be_present,
    )
    expect(state_store).to have_received(:write).with(application_ecf_id: application.ecf_id)
    expect(Emails::SendApplicationSubmissionEmailJob)
      .to have_received(:perform_later).with(application:)
  end

  context "when the funding result is not funded" do
    let(:store_data) do
      super().merge(
        "teacher_catchment" => Institution::OTHER,
        "work_setting" => Institution::PRIVATE_INSTITUTION,
        "funding_eligibility_result" => "ineligible",
        "funding" => "self",
      )
    end

    it "keeps the funding choice and does not associate an out-of-catchment institution" do
      application = user.applications.sole

      expect(application).to have_attributes(
        institution: nil,
        funding_eligibility: "ineligible",
        funding_choice: "self",
      )
    end
  end

  context "when the registration is outside England" do
    let(:store_data) do
      super().merge("teacher_catchment" => Institution::OTHER)
    end

    it "does not associate the selected institution" do
      expect(user.applications.sole.institution).to be_nil
    end
  end
end
