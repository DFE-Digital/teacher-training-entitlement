require "rails_helper"

RSpec.describe Trainings::OutcomesQuery do
  let(:lead_provider) { create(:lead_provider) }
  let(:application) { create(:application, lead_provider:) }
  let(:declaration) { create(:declaration, :completed, :payable, application:, lead_provider:, user: application.user) }

  def result
    described_class.new(lead_provider:, application_ids: [application.id]).call
  end

  it "returns the latest outcome per application" do
    create(:participant_outcome, declaration:, created_at: 2.days.ago)
    latest = create(:participant_outcome, declaration:, created_at: 1.day.ago)

    expect(result[application.id]).to eq(latest)
  end

  it "ignores outcomes of voided declarations" do
    create(:participant_outcome, declaration:)
    declaration.update_columns(state: "voided")

    expect(result).to be_empty
  end

  it "ignores outcomes of other providers' declarations" do
    other = create(:lead_provider)
    other_declaration = create(:declaration, :completed, :payable, application:, lead_provider: other, user: application.user)
    create(:participant_outcome, declaration: other_declaration)

    expect(result).to be_empty
  end

  it "ignores non-completed declarations" do
    started = create(:declaration, :started, :payable, application:, lead_provider:, user: application.user)
    create(:participant_outcome, declaration: started)

    expect(result).to be_empty
  end
end
