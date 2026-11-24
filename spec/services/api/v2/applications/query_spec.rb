require "rails_helper"

RSpec.describe API::V2::Applications::Query do
  let(:lead_provider) { create(:lead_provider) }
  let!(:application) { create(:application, lead_provider:) }

  def ids(filters = {})
    described_class.new(lead_provider:, filters:).application_lead_providers.map { |alp| alp.application.id }
  end

  it "returns current assignments" do
    later = create(:application, lead_provider:)

    expect(ids).to contain_exactly(application.id, later.id)
  end

  it "returns the previous assignment of a reassigned application" do
    application.change_provider!(to: create(:lead_provider))

    expect(described_class.new(lead_provider:).application_lead_providers.map(&:current?)).to eq([false])
  end

  it "returns one assignment per application" do
    other = create(:lead_provider)
    application.change_provider!(to: other)
    application.reload.change_provider!(to: lead_provider)
    application.reload.change_provider!(to: other)

    expect(ids).to eq([application.id])
  end

  it "prefers the current assignment" do
    application.change_provider!(to: create(:lead_provider))
    application.reload.change_provider!(to: lead_provider)

    expect(described_class.new(lead_provider:).application_lead_providers.map(&:current?)).to eq([true])
  end

  it "returns none for any funding_uplift filter" do
    expect(ids(funding_uplift: false)).to be_empty
  end

  it "filters by application email" do
    expect(ids(email: [application.email])).to eq([application.id])
  end

  it "returns none for an unknown email" do
    expect(ids(email: ["nobody@example.com"])).to be_empty
  end

  describe "#sort_keys" do
    it "sorts by effective updated_at with the application ecf_id as tie-breaker by default" do
      query = described_class.new(lead_provider:)

      expect(query.sort_keys.map { |key| key.slice(:name, :direction) }).to eq([
        { name: "updated_at", direction: :asc },
        { name: "id", direction: :asc },
      ])
    end

    it "uses the requested sort" do
      query = described_class.new(lead_provider:, sort: [["created_at", :desc]])

      expect(query.sort_keys.first.slice(:name, :sql, :direction)).to eq(
        name: "created_at", sql: "application_lead_providers.application_created_at", direction: :desc,
      )
    end
  end

  describe "effective updated_at" do
    let(:query) { described_class.new(lead_provider:, filters: { updated_since: 1.day.ago }) }

    def page_sql
      paginator = API::V2::CursorPaginator.new(scope: query.application_lead_providers, keys: query.sort_keys, size: 1)
      cursor = paginator.call.next_cursor || raise("expected a next page")
      sql = nil
      callback = ->(*, payload) { sql = payload[:sql] if payload[:sql].include?("GREATEST") }
      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        API::V2::CursorPaginator.new(scope: query.application_lead_providers, keys: query.sort_keys, size: 1, after: cursor).call
      end
      sql
    end

    before { create(:application, lead_provider:) }

    it "is computed once in a cursor page query with updated_since" do
      expect(page_sql.scan("GREATEST").size).to eq(1)
    end

    it "does not read declarations" do
      expect(page_sql).not_to include("declarations")
    end
  end

  describe "#application_lead_provider" do
    it "finds a visible application by ecf_id" do
      expect(described_class.new(lead_provider:).application_lead_provider(ecf_id: application.ecf_id).application).to eq(application)
    end

    it "raises not found for another provider's application" do
      other = create(:application, lead_provider: create(:lead_provider))

      expect { described_class.new(lead_provider:).application_lead_provider(ecf_id: other.ecf_id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
