require "rails_helper"

RSpec.describe "API V2 applications effective updated_at", type: :request do
  include_context "with API V2 enabled"

  let(:lead_provider) { create(:lead_provider) }
  let(:created_at) { Time.zone.parse("2025-01-01T09:00:00Z") }
  let(:changed_at) { Time.zone.parse("2025-03-01T09:00:00Z") }
  let!(:application) { travel_to(created_at) { create(:application, lead_provider:) } }

  def json
    JSON.parse(response.body)
  end

  def updated_at
    api_get("/api/v2/applications/#{application.ecf_id}", lead_provider:)
    Time.zone.parse(json["data"]["attributes"]["updated_at"])
  end

  def listed_ids(updated_since)
    api_get("/api/v2/applications", lead_provider:, params: { filter: { updated_since: updated_since.utc.iso8601 } })
    json["data"].map { |a| a["id"] }
  end

  def create_declaration(state:, type: :completed, provider: lead_provider)
    create(:declaration, type, state:, application:, lead_provider: provider, user: application.user)
  end

  def record_outcome(application)
    ParticipantOutcomes::Create.new(application:, state: "passed", completion_date: "2025-02-01").create_outcome
  end

  it "is the application's updated_at when nothing related changed" do
    expect(updated_at).to eq(created_at)
  end

  it "is the same in the list and show" do
    api_get("/api/v2/applications", lead_provider:)
    listed = json["data"].first["attributes"]["updated_at"]

    expect(Time.zone.parse(listed)).to eq(updated_at)
  end

  {
    "the application is updated" => ->(app) { app.touch },
    "the teacher gets a TRN" => ->(app) { app.user.update!(trn: "0099999") },
    "the application is reassigned" => ->(app) { app.change_provider!(to: create(:lead_provider)) },
    "the institution changes" => ->(app) { app.institution.touch },
  }.each do |description, change|
    context "when #{description}" do
      before do
        application.update_columns(updated_at: created_at)
        travel_to(changed_at) { instance_exec(application.reload, &change) }
      end

      it "reflects the change" do
        expect(updated_at).to be_within(1.second).of(changed_at)
      end

      it "matches filter[updated_since] from the change" do
        expect(listed_ids(changed_at - 1.second)).to eq([application.ecf_id])
      end
    end
  end

  # Declarations and outcomes are not V2 application attributes: statement runs,
  # clawbacks and voids must not make providers re-sync applications. Declarations
  # are created and changed at the current time (declaration dates can't be in the
  # future), well after the application was last changed.
  {
    "a declaration becomes payable" => [:eligible, ->(declaration) { declaration.mark_payable! }],
    "a declaration is paid" => [:payable, ->(declaration) { declaration.mark_paid! }],
    "a declaration is voided" => [:submitted, ->(declaration) { declaration.mark_voided! }],
    "a declaration is clawed back" => [:paid, ->(declaration) { declaration.clawback! }],
    "the provider records an outcome" => [:payable, ->(declaration) { record_outcome(declaration.application) }],
  }.each do |description, (state, change)|
    context "when #{description}" do
      before do
        declaration = create_declaration(state:)
        application.update_columns(updated_at: created_at)
        instance_exec(declaration.reload, &change)
      end

      it "does not change updated_at" do
        expect(updated_at).to eq(created_at)
      end

      it "is not matched by filter[updated_since] after the creation" do
        expect(listed_ids(created_at + 1.second)).to eq([])
      end
    end
  end

  it "ignores insignificant teacher changes" do
    travel_to(changed_at) { application.user.update!(refresh_token_updated_at: Time.zone.now) }

    expect(updated_at).to eq(created_at)
  end

  it "excludes applications not changed since filter[updated_since]" do
    expect(listed_ids(created_at + 1.second)).to eq([])
  end
end
