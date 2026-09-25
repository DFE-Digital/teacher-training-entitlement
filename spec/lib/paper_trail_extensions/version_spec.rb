require "rails_helper"

RSpec.describe PaperTrailExtensions::Version, :versioning, type: :model do
  before do
    freeze_time
    PaperTrail.request.whodunnit = "Admin 1"
    allow(StreamAnalyticsEventToBigQueryJob).to receive(:send_event).and_call_original
  end

  context "when a model has paper trail enabled" do
    let(:user) { create(:user, full_name: "John Doe") }
    let(:user_name) { "Admin 1" }

    context "when a record is created" do
      let(:expected_data) do
        {
          "item_table_name" => "users",
          "item_id" => user.id,
          "event" => "create",
          "whodunnit" => user_name,
          "created_at" => Time.zone.now,
          "note" => nil,
          "object_changes" => %w[
            id
            created_at
            date_of_birth
            ecf_id
            email
            full_name
            significantly_updated_at
            trn
          ],
        }
      end

      before { user }

      it "calls StreamAnalyticsEventToBigQueryJob" do
        expect(StreamAnalyticsEventToBigQueryJob).to have_received(:send_event).with(type: :version, user: user_name, data: expected_data)
      end
    end

    context "when a user is updated" do
      let(:expected_data) do
        {
          "item_table_name" => "users",
          "item_id" => user.id,
          "event" => "update",
          "whodunnit" => user_name,
          "created_at" => Time.zone.now,
          "note" => nil,
          "object_changes" => %w[
            full_name
          ],
        }
      end

      before do
        user
        user.update!(full_name: "New name")
      end

      it "calls StreamAnalyticsEventToBigQueryJob" do
        expect(StreamAnalyticsEventToBigQueryJob).to have_received(:send_event).with(type: :version, user: user_name, data: expected_data)
      end
    end

    context "when a record is destroyed" do
      let(:expected_data) do
        {
          "item_table_name" => "users",
          "item_id" => user.id,
          "event" => "destroy",
          "whodunnit" => user_name,
          "created_at" => Time.zone.now,
          "note" => nil,
          "object_changes" => user.attributes.keys.excluding(%w[updated_at raw_tra_provider_data feature_flag_id refresh_token refresh_token_updated_at]),
        }
      end

      before do
        user
        user.destroy!
      end

      it "calls StreamAnalyticsEventToBigQueryJob" do
        expect(StreamAnalyticsEventToBigQueryJob).to have_received(:send_event).with(type: :version, user: user_name, data: expected_data)
      end
    end
  end
end
