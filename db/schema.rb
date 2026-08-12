# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_11_140000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "btree_gin"
  enable_extension "citext"
  enable_extension "fuzzystrmatch"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "api_token_scopes", ["lead_provider", "teacher_record_service"]
  create_enum "application_statuses", ["pending", "accepted", "started", "rejected", "completed", "deferred", "withdrawn"]
  create_enum "course_group", ["reception", "send"]
  create_enum "declaration_state_reasons", ["duplicate"]
  create_enum "declaration_states", ["submitted", "eligible", "payable", "paid", "voided", "ineligible", "awaiting_clawback", "clawed_back"]
  create_enum "declaration_types", ["started", "retained-1", "retained-2", "completed"]
  create_enum "email_updates_statuses", ["npd_registration_open"]
  create_enum "funding_choices", ["school", "trust", "self", "another", "employer"]
  create_enum "kind_of_nurseries", ["local_authority_maintained_nursery", "preschool_class_as_part_of_school", "private_nursery", "another_early_years_setting", "childminder"]
  create_enum "outcome_states", ["passed", "failed", "voided"]
  create_enum "review_statuses", ["needs_review", "awaiting_information", "reregister", "decision_made"]
  create_enum "statement_states", ["open", "payable", "paid"]
  create_enum "statements_frequency_types", ["monthly"]

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "adjustments", force: :cascade do |t|
    t.decimal "amount", precision: 18, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.bigint "statement_id", null: false
    t.datetime "updated_at", null: false
    t.index ["statement_id"], name: "index_adjustments_on_statement_id"
  end

  create_table "admin_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", limit: 64, null: false
    t.string "full_name", limit: 64, null: false
    t.datetime "otp_expires_at", precision: nil
    t.text "otp_hash"
    t.boolean "super_admin", default: false, null: false
    t.datetime "updated_at", null: false
  end

  create_table "api_tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hashed_token", null: false
    t.datetime "last_used_at"
    t.bigint "lead_provider_id"
    t.enum "scope", default: "lead_provider", enum_type: "api_token_scopes"
    t.datetime "updated_at", null: false
    t.index ["hashed_token"], name: "index_api_tokens_on_hashed_token", unique: true
    t.index ["lead_provider_id"], name: "index_api_tokens_on_lead_provider_id"
    t.check_constraint "lead_provider_id IS NOT NULL AND scope = 'lead_provider'::api_token_scopes OR lead_provider_id IS NULL AND scope <> 'lead_provider'::api_token_scopes"
  end

  create_table "application_events", force: :cascade do |t|
    t.bigint "application_id", null: false
    t.datetime "created_at", null: false
    t.string "event", null: false
    t.bigint "lead_provider_id"
    t.jsonb "metadata", default: {}
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["application_id"], name: "index_application_events_on_application_id"
    t.index ["created_at"], name: "index_application_events_on_created_at"
    t.index ["event"], name: "index_application_events_on_event"
    t.index ["lead_provider_id"], name: "index_application_events_on_lead_provider_id"
    t.index ["type"], name: "index_application_events_on_type"
  end

  create_table "application_lead_providers", force: :cascade do |t|
    t.bigint "application_id"
    t.datetime "assigned_at"
    t.datetime "created_at", null: false
    t.boolean "current", default: false
    t.bigint "lead_provider_id"
    t.datetime "unassigned_at"
    t.datetime "updated_at", null: false
    t.index ["application_id"], name: "index_application_lead_providers_on_application_id"
    t.index ["lead_provider_id", "application_id"], name: "idx_unique_current_application_lead_providers", unique: true, where: "(current = true)"
    t.index ["lead_provider_id"], name: "index_application_lead_providers_on_lead_provider_id"
  end

  create_table "applications", force: :cascade do |t|
    t.bigint "course_cohort_id"
    t.datetime "created_at", null: false
    t.uuid "ecf_id", default: -> { "gen_random_uuid()" }, null: false
    t.boolean "eligible_for_funding", default: false, null: false
    t.boolean "funded_place"
    t.enum "funding_choice", enum_type: "funding_choices"
    t.string "funding_eligiblity_status_code"
    t.bigint "institution_id"
    t.enum "kind_of_nursery", enum_type: "kind_of_nurseries"
    t.string "notes"
    t.integer "number_of_pupils", default: 0
    t.string "on_submission_trn"
    t.text "participant_outcome_state"
    t.boolean "primary_establishment", default: false
    t.jsonb "raw_application_data", default: {}
    t.string "referred_by_return_to_teaching_adviser"
    t.enum "review_status", enum_type: "review_statuses"
    t.enum "status", enum_type: "application_statuses"
    t.boolean "targeted_support_funding_eligibility", default: false
    t.text "teacher_catchment"
    t.text "teacher_catchment_country"
    t.string "teacher_catchment_iso_country_code", limit: 3
    t.text "ukprn"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.text "work_setting"
    t.boolean "works_in_childcare"
    t.boolean "works_in_nursery"
    t.boolean "works_in_school"
    t.index ["course_cohort_id"], name: "index_applications_on_course_cohort_id"
    t.index ["ecf_id"], name: "index_applications_on_ecf_id", unique: true
    t.index ["institution_id"], name: "index_applications_on_institution_id"
    t.index ["status"], name: "index_applications_on_status"
    t.index ["user_id", "course_cohort_id"], name: "index_applications_on_user_id_and_course_cohort_id", unique: true
    t.index ["user_id"], name: "index_applications_on_user_id"
  end

  create_table "bulk_operations", force: :cascade do |t|
    t.integer "admin_id", null: false
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "ran_by_admin_id"
    t.jsonb "result"
    t.integer "row_count"
    t.datetime "started_at"
    t.string "type", null: false
    t.datetime "updated_at", null: false
  end

  create_table "closed_registration_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.datetime "updated_at", null: false
  end

  create_table "cohorts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description", limit: 50, null: false
    t.uuid "ecf_id"
    t.boolean "funding_cap", default: false, null: false
    t.string "identifier", null: false
    t.date "registration_ends_at"
    t.date "registration_starts_at"
    t.integer "start_year", null: false
    t.datetime "updated_at", null: false
    t.index ["description"], name: "index_cohorts_on_description", unique: true
    t.index ["ecf_id"], name: "index_cohorts_on_ecf_id", unique: true
    t.index ["identifier"], name: "index_cohorts_on_identifier", unique: true
    t.index ["start_year"], name: "index_cohorts_on_start_year"
  end

  create_table "contract_years", force: :cascade do |t|
    t.integer "academic_year"
    t.bigint "course_id", null: false
    t.string "course_url"
    t.datetime "created_at", null: false
    t.string "email"
    t.bigint "lead_provider_id", null: false
    t.integer "recruitment_target"
    t.string "secondary_form_url"
    t.decimal "service_fee"
    t.decimal "teacher_funding"
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_contract_years_on_course_id"
    t.index ["lead_provider_id", "course_id", "academic_year"], name: "idx_on_lead_provider_id_course_id_academic_year_c921fdb2b9", unique: true
    t.index ["lead_provider_id"], name: "index_contract_years_on_lead_provider_id"
  end

  create_table "course_cohort_providers", force: :cascade do |t|
    t.bigint "course_cohort_id", null: false
    t.datetime "created_at", null: false
    t.bigint "lead_provider_id", null: false
    t.integer "recruitment_target"
    t.decimal "teacher_funding"
    t.datetime "updated_at", null: false
    t.index ["course_cohort_id", "lead_provider_id"], name: "idx_on_course_cohort_id_lead_provider_id_3527d5c43f", unique: true
    t.index ["course_cohort_id"], name: "index_course_cohort_providers_on_course_cohort_id"
    t.index ["lead_provider_id"], name: "index_course_cohort_providers_on_lead_provider_id"
  end

  create_table "course_cohorts", force: :cascade do |t|
    t.integer "academic_year"
    t.bigint "cohort_id", null: false
    t.bigint "course_id", null: false
    t.datetime "created_at", null: false
    t.uuid "ecf_id", default: -> { "gen_random_uuid()" }, null: false
    t.bigint "schedule_id"
    t.datetime "updated_at", null: false
    t.index ["cohort_id"], name: "index_course_cohorts_on_cohort_id"
    t.index ["course_id", "cohort_id"], name: "index_course_cohorts_on_course_id_and_cohort_id", unique: true
    t.index ["course_id"], name: "index_course_cohorts_on_course_id"
    t.index ["ecf_id"], name: "index_course_cohorts_on_ecf_id", unique: true
    t.index ["schedule_id"], name: "index_course_cohorts_on_schedule_id"
  end

  create_table "courses", force: :cascade do |t|
    t.enum "course_group", enum_type: "course_group"
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "display", default: true
    t.uuid "ecf_id"
    t.string "identifier"
    t.text "name", null: false
    t.integer "position", default: 0
    t.string "short_code"
    t.datetime "updated_at", null: false
    t.index ["ecf_id"], name: "index_courses_on_ecf_id", unique: true
    t.index ["identifier"], name: "index_courses_on_identifier", unique: true
  end

  create_table "declarations", force: :cascade do |t|
    t.bigint "application_id", null: false
    t.bigint "clawback_declaration_id"
    t.bigint "cohort_id"
    t.datetime "created_at", null: false
    t.datetime "declaration_date", precision: nil
    t.enum "declaration_type", enum_type: "declaration_types"
    t.bigint "delivery_partner_id"
    t.uuid "ecf_id", default: -> { "gen_random_uuid()" }, null: false
    t.bigint "lead_provider_id", null: false
    t.bigint "milestone_id"
    t.bigint "paid_declaration_id"
    t.bigint "secondary_delivery_partner_id"
    t.enum "state", default: "submitted", null: false, enum_type: "declaration_states"
    t.enum "state_reason", enum_type: "declaration_state_reasons"
    t.bigint "statement_id"
    t.bigint "superseded_by_id"
    t.string "type"
    t.datetime "updated_at", null: false
    t.decimal "value"
    t.index ["application_id", "milestone_id", "type"], name: "index_declarations_on_application_id_and_milestone_id", unique: true, where: "(state = ANY (ARRAY['eligible'::declaration_states, 'payable'::declaration_states, 'paid'::declaration_states, 'submitted'::declaration_states]))"
    t.index ["application_id"], name: "index_declarations_on_application_id"
    t.index ["clawback_declaration_id"], name: "index_declarations_on_clawback_declaration_id"
    t.index ["cohort_id"], name: "index_declarations_on_cohort_id"
    t.index ["delivery_partner_id"], name: "index_declarations_on_delivery_partner_id"
    t.index ["ecf_id"], name: "index_declarations_on_ecf_id", unique: true
    t.index ["lead_provider_id"], name: "index_declarations_on_lead_provider_id"
    t.index ["paid_declaration_id"], name: "index_declarations_on_paid_declaration_id"
    t.index ["secondary_delivery_partner_id"], name: "index_declarations_on_secondary_delivery_partner_id"
    t.index ["statement_id"], name: "index_declarations_on_statement_id"
    t.index ["superseded_by_id"], name: "index_declarations_on_superseded_by_id"
    t.index ["type"], name: "index_declarations_on_type"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "attempts", default: 0, null: false
    t.datetime "created_at"
    t.string "cron"
    t.datetime "failed_at", precision: nil
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "locked_at", precision: nil
    t.string "locked_by"
    t.integer "priority", default: 0, null: false
    t.string "queue"
    t.datetime "run_at", precision: nil
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "delivery_partners", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "ecf_id", default: -> { "gen_random_uuid()" }, null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["ecf_id"], name: "index_delivery_partners_on_ecf_id", unique: true
    t.index ["name"], name: "index_delivery_partners_on_name", unique: true
  end

  create_table "delivery_partnerships", force: :cascade do |t|
    t.bigint "cohort_id"
    t.bigint "course_cohort_id"
    t.datetime "created_at", null: false
    t.bigint "delivery_partner_id", null: false
    t.bigint "lead_provider_id", null: false
    t.datetime "updated_at", null: false
    t.index ["cohort_id"], name: "index_delivery_partnerships_on_cohort_id"
    t.index ["course_cohort_id"], name: "index_delivery_partnerships_on_course_cohort_id"
    t.index ["delivery_partner_id", "lead_provider_id", "cohort_id"], name: "idx_on_delivery_partner_id_lead_provider_id_cohort__10d5da32cd", unique: true
    t.index ["delivery_partner_id", "lead_provider_id", "course_cohort_id"], name: "idx_delivery_partnerships_on_partner_provider_course_cohort", unique: true
    t.index ["delivery_partner_id"], name: "index_delivery_partnerships_on_delivery_partner_id"
    t.index ["lead_provider_id"], name: "index_delivery_partnerships_on_lead_provider_id"
  end

  create_table "eligibility_list_entries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "identifier", null: false
    t.string "identifier_type", null: false
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.index ["identifier"], name: "index_eligibility_list_entries_on_identifier"
    t.index ["type", "identifier", "identifier_type"], name: "idx_on_type_identifier_identifier_type_3a4f491990", unique: true
    t.index ["type"], name: "index_eligibility_list_entries_on_type"
  end

  create_table "financial_change_logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "data_changes", null: false
    t.string "operation_description", null: false
    t.datetime "updated_at", null: false
  end

  create_table "flipper_features", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_flipper_features_on_key", unique: true
  end

  create_table "flipper_gates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "feature_key", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.text "value"
    t.index ["feature_key", "key", "value"], name: "index_flipper_gates_on_feature_key_and_key_and_value", unique: true
  end

  create_table "institutions", force: :cascade do |t|
    t.string "address_1"
    t.string "address_2"
    t.string "address_3"
    t.string "county"
    t.datetime "created_at", null: false
    t.string "institution_reference_number"
    t.bigint "institutionable_id", null: false
    t.string "institutionable_type", null: false
    t.string "name"
    t.string "postcode"
    t.string "postcode_without_spaces"
    t.string "region"
    t.virtual "search_vector", type: :tsvector, as: "to_tsvector('english'::regconfig, (((((COALESCE(name, ''::character varying))::text || ' '::text) || (COALESCE(postcode, ''::character varying))::text) || ' '::text) || (COALESCE(postcode_without_spaces, ''::character varying))::text))", stored: true
    t.string "town"
    t.datetime "updated_at", null: false
    t.index ["institution_reference_number"], name: "index_institutions_on_institution_reference_number"
    t.index ["institutionable_type", "institutionable_id"], name: "idx_on_institutionable_type_institutionable_id_e617e86838", unique: true
    t.index ["search_vector"], name: "index_institutions_on_search_vector", using: :gin
  end

  create_table "lead_providers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "ecf_id"
    t.string "email"
    t.string "hint"
    t.text "name", null: false
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["ecf_id"], name: "index_lead_providers_on_ecf_id", unique: true
  end

  create_table "legacy_passed_participant_outcomes", force: :cascade do |t|
    t.date "completion_date", null: false
    t.string "course_short_code", null: false
    t.datetime "created_at", null: false
    t.string "trn", null: false
    t.datetime "updated_at", null: false
    t.index ["trn"], name: "index_legacy_passed_participant_outcomes_on_trn"
  end

  create_table "local_authorities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "high_pupil_premium", default: false, null: false
    t.datetime "updated_at", null: false
  end

  create_table "milestones", force: :cascade do |t|
    t.date "acceptance_window_end_date"
    t.date "acceptance_window_start_date"
    t.bigint "course_cohort_id", null: false
    t.datetime "created_at", null: false
    t.enum "declaration_type", null: false, enum_type: "declaration_types"
    t.decimal "payment_amount", precision: 10, scale: 2
    t.datetime "updated_at", null: false
    t.index ["course_cohort_id", "declaration_type"], name: "index_milestones_on_course_cohort_id_and_declaration_type", unique: true
    t.index ["course_cohort_id"], name: "index_milestones_on_course_cohort_id"
  end

  create_table "participant_id_changes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "ecf_id"
    t.uuid "from_participant_id", null: false
    t.uuid "to_participant_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["ecf_id"], name: "index_participant_id_changes_on_ecf_id", unique: true
    t.index ["from_participant_id"], name: "index_participant_id_changes_on_from_participant_id"
    t.index ["to_participant_id"], name: "index_participant_id_changes_on_to_participant_id"
    t.index ["user_id"], name: "index_participant_id_changes_on_user_id"
  end

  create_table "participant_outcome_api_requests", force: :cascade do |t|
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
    t.index ["ecf_id"], name: "index_participant_outcome_api_requests_on_ecf_id", unique: true
    t.index ["participant_outcome_id"], name: "index_participant_outcome_api_requests_on_participant_outcome"
  end

  create_table "participant_outcomes", force: :cascade do |t|
    t.date "completion_date", null: false
    t.datetime "created_at", null: false
    t.bigint "declaration_id", null: false
    t.uuid "ecf_id", default: -> { "gen_random_uuid()" }, null: false
    t.boolean "qualified_teachers_api_request_successful"
    t.datetime "sent_to_qualified_teachers_api_at"
    t.enum "state", null: false, enum_type: "outcome_states"
    t.datetime "updated_at", null: false
    t.index ["declaration_id", "created_at"], name: "index_participant_outcomes_on_declaration_id_and_created_at"
    t.index ["declaration_id"], name: "index_participant_outcomes_on_declaration_id"
    t.index ["ecf_id"], name: "index_participant_outcomes_on_ecf_id", unique: true
  end

  create_table "private_childcare_providers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "disabled_at"
    t.json "early_years_individual_registers", default: []
    t.text "local_authority"
    t.boolean "provider_compulsory_childcare_register_flag"
    t.boolean "provider_early_years_register_flag"
    t.datetime "updated_at", null: false
  end

  create_table "registration_interests", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.citext "email", null: false
    t.boolean "notified", default: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_registration_interests_on_email", unique: true
  end

  create_table "reports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "data"
    t.text "identifier", null: false
    t.datetime "updated_at", null: false
  end

  create_table "schedules", force: :cascade do |t|
    t.date "acceptance_window_end"
    t.date "acceptance_window_start"
    t.enum "allowed_declaration_types", default: ["started", "retained-1", "retained-2", "completed"], array: true, enum_type: "declaration_types"
    t.bigint "cohort_id", null: false
    t.enum "course_group", enum_type: "course_group"
    t.datetime "created_at", null: false
    t.uuid "ecf_id"
    t.string "identifier", null: false
    t.string "name", null: false
    t.integer "policy_descriptor"
    t.date "training_ends_at"
    t.date "training_starts_at"
    t.datetime "updated_at", null: false
    t.index ["cohort_id"], name: "index_schedules_on_cohort_id"
    t.index ["ecf_id"], name: "index_schedules_on_ecf_id", unique: true
    t.index ["identifier", "cohort_id"], name: "index_schedules_on_identifier_and_cohort_id", unique: true
  end

  create_table "schools", force: :cascade do |t|
    t.date "close_date"
    t.datetime "created_at", null: false
    t.text "establishment_status_code"
    t.text "establishment_status_name"
    t.text "establishment_type_code"
    t.text "establishment_type_name"
    t.boolean "eyl_funding_eligible", default: false
    t.boolean "high_pupil_premium", default: false, null: false
    t.text "la_code"
    t.text "la_name"
    t.date "last_changed_date"
    t.integer "number_of_pupils"
    t.string "phase_name", default: "Not applicable"
    t.integer "phase_type", default: 0
    t.text "ukprn"
    t.datetime "updated_at", null: false
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "data"
    t.string "session_id", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "statements", force: :cascade do |t|
    t.integer "academic_year"
    t.datetime "created_at", null: false
    t.date "deadline_date"
    t.uuid "ecf_id", default: -> { "gen_random_uuid()" }, null: false
    t.enum "frequency", enum_type: "statements_frequency_types"
    t.bigint "lead_provider_id", null: false
    t.datetime "marked_as_paid_at"
    t.boolean "output_fee", default: true, null: false
    t.date "payment_date"
    t.decimal "reconcile_amount", precision: 8, scale: 2
    t.date "start_date"
    t.enum "state", default: "open", null: false, enum_type: "statement_states"
    t.datetime "updated_at", null: false
    t.index ["ecf_id"], name: "index_statements_on_ecf_id", unique: true
    t.index ["lead_provider_id", "start_date", "frequency"], name: "index_statements_on_lead_provider_id_start_date_frequency", unique: true
    t.index ["lead_provider_id"], name: "index_statements_on_lead_provider_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "active_alert", default: false
    t.datetime "archived_at"
    t.string "archived_email"
    t.datetime "created_at", null: false
    t.date "date_of_birth"
    t.uuid "ecf_id", default: -> { "gen_random_uuid()" }, null: false
    t.string "email", default: "", null: false
    t.enum "email_updates_status", enum_type: "email_updates_statuses"
    t.string "email_updates_unsubscribe_key"
    t.string "feature_flag_id"
    t.text "full_name"
    t.text "national_insurance_number"
    t.boolean "notify_user_for_future_reg", default: false
    t.string "one_login_id"
    t.string "preferred_name"
    t.string "provider"
    t.jsonb "raw_tra_provider_data"
    t.text "refresh_token"
    t.datetime "refresh_token_updated_at"
    t.datetime "significantly_updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "trn"
    t.string "trn_lookup_status"
    t.datetime "trn_requested_at"
    t.datetime "updated_at", null: false
    t.datetime "updated_from_tra_at", precision: nil
    t.index ["created_at"], name: "index_users_on_created_at"
    t.index ["ecf_id"], name: "index_users_on_ecf_id", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["one_login_id"], name: "index_users_on_one_login_id", unique: true
    t.index ["provider"], name: "index_users_on_provider"
    t.index ["refresh_token_updated_at"], name: "index_users_on_refresh_token_updated_at"
    t.index ["significantly_updated_at"], name: "index_users_on_significantly_updated_at"
    t.index ["trn"], name: "index_users_on_trn"
  end

  create_table "versions", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.string "event", null: false
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.string "note"
    t.json "object"
    t.json "object_changes"
    t.string "whodunnit"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
    t.index ["whodunnit"], name: "index_versions_on_whodunnit"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "adjustments", "statements"
  add_foreign_key "api_tokens", "lead_providers"
  add_foreign_key "application_events", "applications"
  add_foreign_key "application_events", "lead_providers"
  add_foreign_key "applications", "institutions"
  add_foreign_key "applications", "users"
  add_foreign_key "contract_years", "courses"
  add_foreign_key "contract_years", "lead_providers"
  add_foreign_key "course_cohort_providers", "course_cohorts"
  add_foreign_key "course_cohort_providers", "lead_providers"
  add_foreign_key "course_cohorts", "cohorts"
  add_foreign_key "course_cohorts", "courses"
  add_foreign_key "declarations", "applications"
  add_foreign_key "declarations", "cohorts"
  add_foreign_key "declarations", "declarations", column: "superseded_by_id"
  add_foreign_key "declarations", "delivery_partners"
  add_foreign_key "declarations", "delivery_partners", column: "secondary_delivery_partner_id"
  add_foreign_key "declarations", "lead_providers"
  add_foreign_key "delivery_partnerships", "cohorts"
  add_foreign_key "delivery_partnerships", "course_cohorts", validate: false
  add_foreign_key "delivery_partnerships", "delivery_partners"
  add_foreign_key "delivery_partnerships", "lead_providers"
  add_foreign_key "milestones", "course_cohorts"
  add_foreign_key "participant_id_changes", "users"
  add_foreign_key "participant_outcome_api_requests", "participant_outcomes"
  add_foreign_key "participant_outcomes", "declarations"
  add_foreign_key "schedules", "cohorts"
  add_foreign_key "statements", "lead_providers"
end
