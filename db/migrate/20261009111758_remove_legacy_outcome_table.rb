class RemoveLegacyOutcomeTable < ActiveRecord::Migration[8.1]
  def change
    drop_table :legacy_passed_participant_outcomes do |t|
      t.date "completion_date", null: false
      t.string "course_short_code", null: false
      t.datetime "created_at", null: false
      t.string "trn", null: false
      t.datetime "updated_at", null: false
    end

    drop_table :participant_outcome_api_requests do |t|
      t.datetime "created_at", null: false
      t.uuid "ecf_id", default: -> { "gen_random_uuid()" }, null: false
      t.bigint "participant_outcome_id", null: false
      t.jsonb "request_body"
      t.jsonb "request_headers"
      t.string "request_path"
      t.jsonb "response_body"
      t.jsonb "response_headers"
      t.integer "status_code"
      t.datetime "updated_at", null: false
    end
  end
end
