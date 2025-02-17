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

ActiveRecord::Schema[7.1].define(version: 2025_02_17_150315) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "active_storage_attachments", id: :serial, force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :serial, force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", precision: nil, null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata", default: "{}"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
    t.index ["metadata"], name: "index_active_storage_blobs_on_metadata"
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "activities", id: :serial, force: :cascade do |t|
    t.uuid "added_by_user_id"
    t.text "body"
    t.bigint "business_id"
    t.bigint "correspondence_id"
    t.datetime "created_at", precision: nil, null: false
    t.integer "investigation_id"
    t.bigint "investigation_product_id"
    t.jsonb "metadata"
    t.string "title"
    t.string "type", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["business_id"], name: "index_activities_on_business_id"
    t.index ["correspondence_id"], name: "index_activities_on_correspondence_id"
    t.index ["investigation_id"], name: "index_activities_on_investigation_id"
    t.index ["investigation_product_id"], name: "index_activities_on_investigation_product_id"
    t.index ["type"], name: "index_activities_on_type"
  end

  create_table "api_tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.datetime "last_used_at"
    t.jsonb "metadata", default: {}
    t.string "name"
    t.string "token"
    t.boolean "transient", default: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["token"], name: "index_api_tokens_on_token", unique: true
    t.index ["user_id"], name: "index_api_tokens_on_user_id"
  end

  create_table "bulk_products_uploads", force: :cascade do |t|
    t.bigint "business_id"
    t.datetime "created_at", null: false
    t.bigint "investigation_business_id"
    t.bigint "investigation_id"
    t.jsonb "products_cache", default: []
    t.datetime "submitted_at", precision: nil
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.index ["business_id"], name: "index_bulk_products_uploads_on_business_id"
    t.index ["investigation_business_id"], name: "index_bulk_products_uploads_on_investigation_business_id"
    t.index ["investigation_id"], name: "index_bulk_products_uploads_on_investigation_id"
    t.index ["user_id"], name: "index_bulk_products_uploads_on_user_id"
  end

  create_table "bulk_products_uploads_products", id: false, force: :cascade do |t|
    t.bigint "bulk_products_upload_id", null: false
    t.bigint "product_id", null: false
  end

  create_table "business_exports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "params"
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.index ["user_id"], name: "index_business_exports_on_user_id"
  end

  create_table "businesses", id: :serial, force: :cascade do |t|
    t.uuid "added_by_user_id"
    t.string "company_number"
    t.datetime "created_at", precision: nil, null: false
    t.string "legal_name"
    t.bigint "online_marketplace_id"
    t.string "trading_name", null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "case_exports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "params"
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.index ["user_id"], name: "index_case_exports_on_user_id"
  end

  create_table "collaborations", force: :cascade do |t|
    t.uuid "added_by_user_id"
    t.uuid "collaborator_id", null: false
    t.string "collaborator_type", null: false
    t.datetime "created_at", precision: nil, null: false
    t.integer "investigation_id", null: false
    t.text "message"
    t.string "type", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["investigation_id", "collaborator_id"], name: "index_collaborations_on_investigation_id_and_collaborator_id", unique: true, where: "(((type)::text <> 'Collaboration::CreatorTeam'::text) AND ((type)::text <> 'Collaboration::CreatorUser'::text))"
    t.index ["investigation_id", "collaborator_type"], name: "index_collaborations_on_investigation_id_and_collaborator_type", unique: true, where: "((type)::text = 'Collaboration::Access::OwnerTeam'::text)"
    t.index ["investigation_id"], name: "index_collaborations_on_investigation_id"
  end

  create_table "complainants", id: :serial, force: :cascade do |t|
    t.string "complainant_type"
    t.datetime "created_at", precision: nil, null: false
    t.string "email_address"
    t.integer "investigation_id"
    t.string "name"
    t.text "other_details"
    t.string "phone_number"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["investigation_id"], name: "index_complainants_on_investigation_id"
  end

  create_table "contacts", force: :cascade do |t|
    t.uuid "added_by_user_id"
    t.integer "business_id"
    t.datetime "created_at", precision: nil, null: false
    t.string "email"
    t.string "job_title"
    t.string "name"
    t.string "phone_number"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["business_id"], name: "index_contacts_on_business_id"
  end

  create_table "corrective_actions", id: :serial, force: :cascade do |t|
    t.string "action", default: "other", null: false
    t.integer "business_id"
    t.datetime "created_at", precision: nil, null: false
    t.date "date_decided"
    t.text "details"
    t.string "duration"
    t.string "geographic_scope"
    t.string "geographic_scopes", default: [], array: true
    t.string "has_online_recall_information"
    t.integer "investigation_id"
    t.bigint "investigation_product_id"
    t.string "legislation", default: [], array: true
    t.string "measure_type"
    t.string "online_recall_information"
    t.text "other_action"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["business_id"], name: "index_corrective_actions_on_business_id"
    t.index ["investigation_id"], name: "index_corrective_actions_on_investigation_id"
    t.index ["investigation_product_id"], name: "index_corrective_actions_on_investigation_product_id"
  end

  create_table "correspondences", force: :cascade do |t|
    t.string "contact_method"
    t.date "correspondence_date"
    t.string "correspondent_name"
    t.string "correspondent_type"
    t.datetime "created_at", precision: nil, null: false
    t.text "details"
    t.string "email_address"
    t.string "email_direction"
    t.string "email_subject"
    t.integer "investigation_id"
    t.string "overview"
    t.string "phone_number"
    t.string "type"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["investigation_id"], name: "index_correspondences_on_investigation_id"
  end

  create_table "csv_exports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "location", null: false
    t.datetime "started_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "document_uploads", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "created_by"
    t.string "description"
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "upload_model_id"
    t.string "upload_model_type"
    t.index ["upload_model_type", "upload_model_id"], name: "index_document_uploads_on_upload_model"
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

  create_table "image_uploads", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "created_by"
    t.datetime "updated_at", null: false
    t.bigint "upload_model_id"
    t.string "upload_model_type"
    t.index ["upload_model_type", "upload_model_id"], name: "index_image_uploads_on_upload_model"
  end

  create_table "investigation_businesses", id: :serial, force: :cascade do |t|
    t.string "authorised_representative_choice"
    t.integer "business_id"
    t.datetime "created_at", precision: nil, null: false
    t.integer "investigation_id"
    t.integer "online_marketplace_id"
    t.string "relationship"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["business_id"], name: "index_investigation_businesses_on_business_id"
    t.index ["investigation_id", "business_id"], name: "idx_on_investigation_id_business_id_8346809cb6"
    t.index ["investigation_id"], name: "index_investigation_businesses_on_investigation_id"
  end

  create_table "investigation_products", id: :serial, force: :cascade do |t|
    t.string "affected_units_status"
    t.string "batch_number"
    t.datetime "created_at", precision: nil, null: false
    t.text "customs_code"
    t.datetime "investigation_closed_at", precision: nil
    t.integer "investigation_id"
    t.text "number_of_affected_units"
    t.integer "product_id"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["investigation_id", "product_id", "investigation_closed_at"], name: "index_investigation_products_on_inv_id_product_id_closed_at", unique: true
    t.index ["investigation_id"], name: "index_investigation_products_on_investigation_id"
    t.index ["product_id"], name: "index_investigation_products_on_product_id"
  end

  create_table "investigations", id: :serial, force: :cascade do |t|
    t.string "complainant_reference"
    t.boolean "coronavirus_related", default: false
    t.string "corrective_action_not_taken_reason"
    t.string "corrective_action_taken"
    t.datetime "created_at", precision: nil, null: false
    t.string "custom_risk_level"
    t.datetime "date_closed", precision: nil
    t.date "date_received"
    t.datetime "deleted_at", precision: nil
    t.string "deleted_by"
    t.text "description"
    t.text "hazard_description"
    t.string "hazard_type"
    t.bigint "image_upload_ids", default: [], array: true
    t.boolean "is_closed", default: false
    t.boolean "is_from_overseas_regulator"
    t.boolean "is_private", default: false, null: false
    t.text "non_compliant_reason"
    t.string "notifying_country"
    t.string "overseas_regulator_country"
    t.string "pretty_id", null: false
    t.string "product_category"
    t.string "received_type"
    t.string "reported_reason"
    t.string "risk_level"
    t.datetime "risk_validated_at", precision: nil
    t.string "risk_validated_by"
    t.string "state"
    t.datetime "submitted_at"
    t.jsonb "tasks_status", default: {}
    t.string "type", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "user_title"
    t.index ["custom_risk_level"], name: "index_investigations_on_custom_risk_level"
    t.index ["deleted_at"], name: "index_investigations_on_deleted_at"
    t.index ["pretty_id"], name: "index_investigations_on_pretty_id", unique: true
    t.index ["submitted_at"], name: "index_investigations_on_submitted_at"
    t.index ["updated_at"], name: "index_investigations_on_updated_at"
  end

  create_table "locations", id: :serial, force: :cascade do |t|
    t.uuid "added_by_user_id"
    t.string "address_line_1"
    t.string "address_line_2"
    t.integer "business_id"
    t.string "city"
    t.string "country"
    t.string "county"
    t.datetime "created_at", precision: nil, null: false
    t.string "name", null: false
    t.string "phone_number"
    t.string "postal_code"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["business_id"], name: "index_locations_on_business_id"
  end

  create_table "online_marketplaces", force: :cascade do |t|
    t.boolean "approved_by_opss"
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_online_marketplaces_on_name", unique: true
  end

  create_table "organisations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "name"
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "prism_associated_investigation_products", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "associated_investigation_id"
    t.datetime "created_at", null: false
    t.bigint "product_id"
    t.datetime "updated_at", null: false
    t.index ["associated_investigation_id"], name: "index_prism_associated_products_on_associated_investigation_id"
    t.index ["product_id"], name: "index_prism_associated_investigation_products_on_product_id"
  end

  create_table "prism_associated_investigations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "investigation_id"
    t.uuid "risk_assessment_id"
    t.datetime "updated_at", null: false
    t.index ["investigation_id"], name: "index_prism_associated_investigations_on_investigation_id"
    t.index ["risk_assessment_id"], name: "index_prism_associated_investigations_on_risk_assessment_id"
  end

  create_table "prism_associated_products", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "product_id"
    t.uuid "risk_assessment_id"
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_prism_associated_products_on_product_id"
    t.index ["risk_assessment_id"], name: "index_prism_associated_products_on_risk_assessment_id"
  end

  create_table "prism_evaluations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "aimed_at_vulnerable_users"
    t.string "comparable_risk_level"
    t.datetime "created_at", null: false
    t.string "designed_to_provide_protective_function"
    t.boolean "factors_to_take_into_account"
    t.text "factors_to_take_into_account_details"
    t.string "featured_in_media"
    t.string "level_of_uncertainty"
    t.string "low_likelihood_high_severity"
    t.string "number_of_products_expected_to_change"
    t.string "other_hazards"
    t.text "other_risk_perception_matters"
    t.string "other_types_of_harm", default: [], array: true
    t.boolean "people_at_increased_risk"
    t.text "people_at_increased_risk_details"
    t.string "relevant_action_by_others"
    t.uuid "risk_assessment_id"
    t.boolean "risk_to_non_users"
    t.string "risk_tolerability"
    t.boolean "sensitivity_analysis"
    t.text "sensitivity_analysis_details"
    t.string "significant_risk_differential"
    t.boolean "uncertainty_level_implications_for_risk_management"
    t.datetime "updated_at", null: false
    t.boolean "user_control_over_risk"
    t.index ["risk_assessment_id"], name: "index_prism_evaluations_on_risk_assessment_id"
  end

  create_table "prism_harm_scenario_step_evidences", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "harm_scenario_step_id"
    t.datetime "updated_at", null: false
    t.index ["harm_scenario_step_id"], name: "index_prism_harm_scenario_step_evidences_on_harm_scenario_step"
  end

  create_table "prism_harm_scenario_steps", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.uuid "harm_scenario_id"
    t.decimal "probability_decimal"
    t.string "probability_evidence"
    t.text "probability_evidence_description"
    t.integer "probability_frequency"
    t.string "probability_type"
    t.datetime "updated_at", null: false
    t.index ["harm_scenario_id"], name: "index_prism_harm_scenario_steps_on_harm_scenario_id"
  end

  create_table "prism_harm_scenarios", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "confirmed_at", precision: nil
    t.datetime "created_at", null: false
    t.text "description"
    t.string "hazard_type"
    t.boolean "multiple_casualties"
    t.string "other_hazard_type"
    t.string "product_aimed_at"
    t.string "product_aimed_at_description"
    t.uuid "risk_assessment_id"
    t.string "severity"
    t.json "tasks_status", default: {}
    t.string "unintended_risks_for", default: [], array: true
    t.datetime "updated_at", null: false
    t.index ["risk_assessment_id"], name: "index_prism_harm_scenarios_on_risk_assessment_id"
  end

  create_table "prism_product_hazards", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "number_of_hazards"
    t.uuid "risk_assessment_id"
    t.datetime "updated_at", null: false
    t.index ["risk_assessment_id"], name: "index_prism_product_hazards_on_risk_assessment_id"
  end

  create_table "prism_product_market_details", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "risk_assessment_id"
    t.jsonb "routing_questions"
    t.string "safety_legislation_standards", default: [], array: true
    t.string "selling_organisation"
    t.integer "total_products_sold"
    t.datetime "updated_at", null: false
    t.index ["risk_assessment_id"], name: "index_prism_product_market_details_on_risk_assessment_id"
  end

  create_table "prism_risk_assessments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "assessment_organisation"
    t.string "assessor_name"
    t.datetime "created_at", null: false
    t.uuid "created_by_user_id"
    t.string "name"
    t.string "overall_product_risk_level"
    t.string "overall_product_risk_methodology"
    t.string "overall_product_risk_plus_label"
    t.string "risk_type"
    t.jsonb "routing_questions"
    t.string "serious_risk_rebuttable_factors"
    t.string "state"
    t.json "tasks_status", default: {}
    t.datetime "updated_at", null: false
  end

  create_table "product_exports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "params"
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.index ["user_id"], name: "index_product_exports_on_user_id"
  end

  create_table "products", id: :serial, force: :cascade do |t|
    t.uuid "added_by_user_id"
    t.string "authenticity"
    t.string "barcode", limit: 15
    t.text "brand"
    t.string "category"
    t.string "country_of_origin"
    t.datetime "created_at", precision: nil, null: false
    t.text "description"
    t.bigint "document_upload_ids", default: [], array: true
    t.string "has_markings"
    t.bigint "image_upload_ids", default: [], array: true
    t.text "markings", array: true
    t.string "name"
    t.uuid "owning_team_id"
    t.string "product_code"
    t.datetime "retired_at", precision: nil
    t.string "subcategory"
    t.datetime "updated_at", precision: nil, null: false
    t.string "webpage"
    t.string "when_placed_on_market"
    t.index ["owning_team_id"], name: "index_products_on_owning_team_id"
    t.index ["retired_at"], name: "index_products_on_retired_at"
  end

  create_table "risk_assessed_products", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.bigint "investigation_product_id"
    t.integer "risk_assessment_id", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["investigation_product_id"], name: "index_risk_assessed_products_on_investigation_product_id"
    t.index ["risk_assessment_id", "investigation_product_id"], name: "index_risk_assessed_products", unique: true
  end

  create_table "risk_assessments", force: :cascade do |t|
    t.uuid "added_by_team_id", null: false
    t.uuid "added_by_user_id", null: false
    t.integer "assessed_by_business_id"
    t.text "assessed_by_other"
    t.uuid "assessed_by_team_id"
    t.date "assessed_on", null: false
    t.datetime "created_at", precision: nil, null: false
    t.text "custom_risk_level"
    t.text "details"
    t.integer "investigation_id", null: false
    t.string "risk_level"
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "roles", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.uuid "entity_id"
    t.string "entity_type", null: false
    t.string "name", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["entity_id", "entity_type"], name: "index_roles_on_entity_id_and_entity_type"
    t.index ["entity_id", "name"], name: "index_roles_on_entity_id_and_name", unique: true
    t.index ["entity_id"], name: "index_roles_on_entity_id"
    t.index ["name", "entity_type", "entity_id"], name: "index_roles_on_name_and_entity_type_and_entity_id", unique: true
  end

  create_table "rollups", force: :cascade do |t|
    t.jsonb "dimensions", default: {}, null: false
    t.string "interval", null: false
    t.string "name", null: false
    t.datetime "time", null: false
    t.float "value"
    t.index ["name", "interval", "time", "dimensions"], name: "index_rollups_on_name_and_interval_and_time_and_dimensions", unique: true
  end

  create_table "teams", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "country"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.string "name"
    t.uuid "organisation_id"
    t.string "regulator_name"
    t.string "team_recipient_email"
    t.string "team_type"
    t.string "ts_acronym"
    t.string "ts_area"
    t.string "ts_region"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["deleted_at"], name: "index_teams_on_deleted_at"
    t.index ["name"], name: "index_teams_on_name"
    t.index ["organisation_id"], name: "index_teams_on_organisation_id"
  end

  create_table "tests", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.date "date"
    t.text "details"
    t.text "failure_details"
    t.integer "investigation_id"
    t.bigint "investigation_product_id"
    t.string "legislation"
    t.string "result"
    t.string "standards_product_was_tested_against", default: [], array: true
    t.date "tso_certificate_issue_date"
    t.string "tso_certificate_reference_number"
    t.string "type"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["investigation_id"], name: "index_tests_on_investigation_id"
    t.index ["investigation_product_id"], name: "index_tests_on_investigation_product_id"
  end

  create_table "ucr_numbers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "investigation_product_id"
    t.string "number"
    t.datetime "updated_at", null: false
    t.index ["investigation_product_id"], name: "index_ucr_numbers_on_investigation_product_id"
  end

  create_table "unexpected_events", force: :cascade do |t|
    t.text "additional_info"
    t.datetime "created_at", null: false
    t.date "date"
    t.integer "investigation_id", null: false
    t.bigint "investigation_product_id"
    t.boolean "is_date_known"
    t.string "severity"
    t.string "severity_other"
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.string "usage"
    t.index ["investigation_product_id"], name: "index_unexpected_events_on_investigation_product_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "account_activated", default: false
    t.datetime "created_at", precision: nil, null: false
    t.string "credential_type"
    t.datetime "current_sign_in_at", precision: nil
    t.inet "current_sign_in_ip"
    t.datetime "deleted_at", precision: nil
    t.string "deleted_by"
    t.string "direct_otp"
    t.datetime "direct_otp_sent_at", precision: nil
    t.string "email"
    t.string "encrypted_otp_secret_key"
    t.string "encrypted_otp_secret_key_iv"
    t.string "encrypted_otp_secret_key_salt"
    t.string "encrypted_password", default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.boolean "has_accepted_declaration", default: false
    t.boolean "has_been_sent_welcome_email", default: false
    t.boolean "has_viewed_introduction", default: false
    t.integer "hash_iterations", default: 27500
    t.text "invitation_token"
    t.datetime "invited_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "keycloak_created_at", precision: nil
    t.datetime "last_activity_at_approx", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.inet "last_sign_in_ip"
    t.datetime "locked_at", precision: nil
    t.string "locked_reason"
    t.text "mobile_number"
    t.boolean "mobile_number_verified", default: false, null: false
    t.string "name"
    t.uuid "organisation_id"
    t.binary "password_salt"
    t.datetime "remember_created_at", precision: nil
    t.datetime "reset_password_sent_at", precision: nil
    t.string "reset_password_token"
    t.integer "second_factor_attempts_count", default: 0
    t.datetime "second_factor_attempts_locked_at", precision: nil
    t.string "secondary_authentication_operation"
    t.integer "sign_in_count", default: 0, null: false
    t.uuid "team_id", null: false
    t.string "unique_session_id"
    t.string "unlock_token"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["account_activated"], name: "index_users_on_account_activated"
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["encrypted_otp_secret_key"], name: "index_users_on_encrypted_otp_secret_key", unique: true
    t.index ["last_activity_at_approx"], name: "index_users_on_last_activity_at_approx"
    t.index ["name"], name: "index_users_on_name"
    t.index ["organisation_id"], name: "index_users_on_organisation_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.string "entity_id"
    t.string "entity_type"
    t.string "event", null: false
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.text "object"
    t.text "object_changes"
    t.string "whodunnit"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "activities", "businesses"
  add_foreign_key "activities", "correspondences"
  add_foreign_key "activities", "investigations"
  add_foreign_key "api_tokens", "users"
  add_foreign_key "collaborations", "investigations"
  add_foreign_key "complainants", "investigations"
  add_foreign_key "corrective_actions", "businesses"
  add_foreign_key "corrective_actions", "investigations"
  add_foreign_key "correspondences", "investigations"
  add_foreign_key "locations", "businesses"
  add_foreign_key "products", "teams", column: "owning_team_id"
  add_foreign_key "risk_assessed_products", "risk_assessments"
  add_foreign_key "risk_assessments", "businesses", column: "assessed_by_business_id"
  add_foreign_key "risk_assessments", "investigations"
  add_foreign_key "risk_assessments", "teams", column: "added_by_team_id"
  add_foreign_key "risk_assessments", "teams", column: "assessed_by_team_id"
  add_foreign_key "risk_assessments", "users", column: "added_by_user_id"
  add_foreign_key "tests", "investigations"
  add_foreign_key "users", "teams"
end
