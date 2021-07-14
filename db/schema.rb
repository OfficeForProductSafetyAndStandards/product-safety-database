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

ActiveRecord::Schema.define(version: 2021_07_12_141941) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  # These are custom enum types that must be created before they can be used in the schema definition
  create_enum "affected_units_statuses", ["exact", "approx", "unknown", "not_relevant"]
  create_enum "authenticities", ["counterfeit", "genuine", "unsure"]
  create_enum "has_markings_values", ["markings_yes", "markings_no", "markings_unknown"]
  create_enum "has_online_recall_information", ["has_online_recall_information_yes", "has_online_recall_information_no", "has_online_recall_information_not_relevant"]
  create_enum "reported_reasons", ["unsafe", "non_compliant", "unsafe_and_non_compliant", "safe_and_compliant"]
  create_enum "risk_levels", ["serious", "high", "medium", "low", "other"]
  create_enum "severities", ["serious", "high", "medium", "low", "unknown_severity", "other"]
  create_enum "usages", ["during_normal_use", "during_misuse", "with_adult_supervision", "without_adult_supervision", "unknown_usage"]
  create_enum "when_placed_on_markets", ["before_2021", "on_or_after_2021", "unknown_date"]

  create_table "active_storage_attachments", id: :serial, force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :serial, force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
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

  create_table "activities", id: :serial, force: :cascade do |t|
    t.text "body"
    t.bigint "business_id"
    t.bigint "correspondence_id"
    t.datetime "created_at", null: false
    t.integer "investigation_id"
    t.jsonb "metadata"
    t.bigint "product_id"
    t.string "title"
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_activities_on_business_id"
    t.index ["correspondence_id"], name: "index_activities_on_correspondence_id"
    t.index ["investigation_id"], name: "index_activities_on_investigation_id"
    t.index ["product_id"], name: "index_activities_on_product_id"
    t.index ["type"], name: "index_activities_on_type"
  end

  create_table "alerts", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "investigation_id"
    t.string "summary"
    t.datetime "updated_at", null: false
    t.index ["investigation_id"], name: "index_alerts_on_investigation_id"
  end

  create_table "businesses", id: :serial, force: :cascade do |t|
    t.string "company_number"
    t.datetime "created_at", null: false
    t.string "legal_name"
    t.string "trading_name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "collaborations", force: :cascade do |t|
    t.uuid "added_by_user_id"
    t.uuid "collaborator_id", null: false
    t.string "collaborator_type", null: false
    t.datetime "created_at", null: false
    t.integer "investigation_id", null: false
    t.text "message"
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.index ["investigation_id", "collaborator_id"], name: "index_collaborations_on_investigation_id_and_collaborator_id", unique: true, where: "(((type)::text <> 'Collaboration::CreatorTeam'::text) AND ((type)::text <> 'Collaboration::CreatorUser'::text))"
    t.index ["investigation_id", "collaborator_type"], name: "index_collaborations_on_investigation_id_and_collaborator_type", unique: true, where: "((type)::text = 'Collaboration::Access::OwnerTeam'::text)"
    t.index ["investigation_id"], name: "index_collaborations_on_investigation_id"
  end

  create_table "complainants", id: :serial, force: :cascade do |t|
    t.string "complainant_type"
    t.datetime "created_at", null: false
    t.string "email_address"
    t.integer "investigation_id"
    t.string "name"
    t.text "other_details"
    t.string "phone_number"
    t.datetime "updated_at", null: false
    t.index ["investigation_id"], name: "index_complainants_on_investigation_id"
  end

  create_table "contacts", force: :cascade do |t|
    t.integer "business_id"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "job_title"
    t.string "name"
    t.string "phone_number"
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_contacts_on_business_id"
  end

  create_table "corrective_actions", id: :serial, force: :cascade do |t|
    t.string "action", default: "other", null: false
    t.integer "business_id"
    t.datetime "created_at", null: false
    t.date "date_decided"
    t.text "details"
    t.string "duration"
    t.string "geographic_scope"
    t.string "geographic_scopes", default: [], array: true
    t.enum "has_online_recall_information", as: "has_online_recall_information"
    t.integer "investigation_id"
    t.string "legislation"
    t.string "measure_type"
    t.string "online_recall_information"
    t.text "other_action"
    t.integer "product_id"
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_corrective_actions_on_business_id"
    t.index ["investigation_id"], name: "index_corrective_actions_on_investigation_id"
    t.index ["product_id"], name: "index_corrective_actions_on_product_id"
  end

  create_table "correspondences", force: :cascade do |t|
    t.string "contact_method"
    t.date "correspondence_date"
    t.string "correspondent_name"
    t.string "correspondent_type"
    t.datetime "created_at", null: false
    t.text "details"
    t.string "email_address"
    t.string "email_direction"
    t.string "email_subject"
    t.integer "investigation_id"
    t.string "overview"
    t.string "phone_number"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["investigation_id"], name: "index_correspondences_on_investigation_id"
  end

  create_table "investigation_businesses", id: :serial, force: :cascade do |t|
    t.integer "business_id"
    t.datetime "created_at", null: false
    t.integer "investigation_id"
    t.string "relationship"
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_investigation_businesses_on_business_id"
    t.index ["investigation_id", "business_id"], name: "index_on_investigation_id_and_business_id", unique: true
    t.index ["investigation_id"], name: "index_investigation_businesses_on_investigation_id"
  end

  create_table "investigation_products", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "investigation_id"
    t.integer "product_id"
    t.datetime "updated_at", null: false
    t.index ["investigation_id", "product_id"], name: "index_investigation_products_on_investigation_id_and_product_id", unique: true
    t.index ["investigation_id"], name: "index_investigation_products_on_investigation_id"
    t.index ["product_id"], name: "index_investigation_products_on_product_id"
  end

  create_table "investigations", id: :serial, force: :cascade do |t|
    t.string "complainant_reference"
    t.boolean "coronavirus_related", default: false
    t.datetime "created_at", null: false
    t.string "custom_risk_level"
    t.datetime "date_closed"
    t.date "date_received"
    t.text "description"
    t.text "hazard_description"
    t.string "hazard_type"
    t.boolean "is_closed", default: false
    t.boolean "is_private", default: false, null: false
    t.text "non_compliant_reason"
    t.string "notifying_country"
    t.string "pretty_id", null: false
    t.string "product_category"
    t.string "received_type"
    t.enum "reported_reason", as: "reported_reasons"
    t.enum "risk_level", as: "risk_levels"
    t.datetime "risk_validated_at"
    t.string "risk_validated_by"
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.string "user_title"
    t.index ["custom_risk_level"], name: "index_investigations_on_custom_risk_level"
    t.index ["pretty_id"], name: "index_investigations_on_pretty_id", unique: true
    t.index ["updated_at"], name: "index_investigations_on_updated_at"
  end

  create_table "locations", id: :serial, force: :cascade do |t|
    t.string "address_line_1"
    t.string "address_line_2"
    t.integer "business_id"
    t.string "city"
    t.string "country"
    t.string "county"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "phone_number"
    t.string "postal_code"
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_locations_on_business_id"
  end

  create_table "organisations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "product_exports", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "products", id: :serial, force: :cascade do |t|
    t.enum "affected_units_status", as: "affected_units_statuses"
    t.enum "authenticity", as: "authenticities"
    t.string "barcode", limit: 15
    t.string "batch_number"
    t.text "brand"
    t.string "category"
    t.string "country_of_origin"
    t.datetime "created_at", null: false
    t.text "customs_code"
    t.text "description"
    t.enum "has_markings", as: "has_markings_values"
    t.text "markings", array: true
    t.string "name"
    t.text "number_of_affected_units"
    t.string "product_code"
    t.string "subcategory"
    t.datetime "updated_at", null: false
    t.string "webpage"
    t.enum "when_placed_on_market", as: "when_placed_on_markets"
  end

  create_table "rapex_imports", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "reference", null: false
    t.datetime "updated_at", null: false
  end

  create_table "risk_assessed_products", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "product_id", null: false
    t.integer "risk_assessment_id", null: false
    t.datetime "updated_at", null: false
    t.index ["risk_assessment_id", "product_id"], name: "index_risk_assessed_products", unique: true
  end

  create_table "risk_assessments", force: :cascade do |t|
    t.uuid "added_by_team_id", null: false
    t.uuid "added_by_user_id", null: false
    t.integer "assessed_by_business_id"
    t.text "assessed_by_other"
    t.uuid "assessed_by_team_id"
    t.date "assessed_on", null: false
    t.datetime "created_at", null: false
    t.text "custom_risk_level"
    t.text "details"
    t.integer "investigation_id", null: false
    t.enum "risk_level", as: "risk_levels"
    t.datetime "updated_at", null: false
  end

  create_table "roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "entity_id"
    t.string "entity_type", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["entity_id", "entity_type"], name: "index_roles_on_entity_id_and_entity_type"
    t.index ["entity_id", "name"], name: "index_roles_on_entity_id_and_name", unique: true
    t.index ["entity_id"], name: "index_roles_on_entity_id"
  end

  create_table "sources", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.integer "sourceable_id"
    t.string "sourceable_type"
    t.string "type"
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.index ["sourceable_id", "sourceable_type"], name: "index_sources_on_sourceable_id_and_sourceable_type"
    t.index ["user_id"], name: "index_sources_on_user_id"
  end

  create_table "teams", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "country"
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "name"
    t.uuid "organisation_id"
    t.string "team_recipient_email"
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_teams_on_deleted_at"
    t.index ["name"], name: "index_teams_on_name"
    t.index ["organisation_id"], name: "index_teams_on_organisation_id"
  end

  create_table "tests", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date"
    t.text "details"
    t.text "failure_details"
    t.integer "investigation_id"
    t.string "legislation"
    t.integer "product_id"
    t.string "result"
    t.string "standards_product_was_tested_against", default: [], array: true
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["investigation_id"], name: "index_tests_on_investigation_id"
    t.index ["product_id"], name: "index_tests_on_product_id"
  end

  create_table "unexpected_events", force: :cascade do |t|
    t.text "additional_info"
    t.datetime "created_at", precision: 6, null: false
    t.date "date"
    t.integer "investigation_id", null: false
    t.boolean "is_date_known"
    t.integer "product_id", null: false
    t.enum "severity", as: "severities"
    t.string "severity_other"
    t.string "type", null: false
    t.datetime "updated_at", precision: 6, null: false
    t.enum "usage", as: "usages"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "account_activated", default: false
    t.datetime "created_at", null: false
    t.string "credential_type"
    t.datetime "current_sign_in_at"
    t.inet "current_sign_in_ip"
    t.datetime "deleted_at"
    t.string "direct_otp"
    t.datetime "direct_otp_sent_at"
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
    t.datetime "invited_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "keycloak_created_at"
    t.datetime "last_sign_in_at"
    t.inet "last_sign_in_ip"
    t.datetime "locked_at"
    t.text "mobile_number"
    t.boolean "mobile_number_verified", default: false, null: false
    t.string "name"
    t.uuid "organisation_id"
    t.binary "password_salt"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "second_factor_attempts_count", default: 0
    t.datetime "second_factor_attempts_locked_at"
    t.string "secondary_authentication_operation"
    t.integer "sign_in_count", default: 0, null: false
    t.uuid "team_id", null: false
    t.string "unlock_token"
    t.datetime "updated_at", null: false
    t.index ["account_activated"], name: "index_users_on_account_activated"
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["encrypted_otp_secret_key"], name: "index_users_on_encrypted_otp_secret_key", unique: true
    t.index ["name"], name: "index_users_on_name"
    t.index ["organisation_id"], name: "index_users_on_organisation_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "activities", "businesses"
  add_foreign_key "activities", "correspondences"
  add_foreign_key "activities", "investigations"
  add_foreign_key "activities", "products"
  add_foreign_key "alerts", "investigations"
  add_foreign_key "collaborations", "investigations"
  add_foreign_key "complainants", "investigations"
  add_foreign_key "corrective_actions", "businesses"
  add_foreign_key "corrective_actions", "investigations"
  add_foreign_key "corrective_actions", "products"
  add_foreign_key "correspondences", "investigations"
  add_foreign_key "locations", "businesses"
  add_foreign_key "risk_assessed_products", "products"
  add_foreign_key "risk_assessed_products", "risk_assessments"
  add_foreign_key "risk_assessments", "businesses", column: "assessed_by_business_id"
  add_foreign_key "risk_assessments", "investigations"
  add_foreign_key "risk_assessments", "teams", column: "added_by_team_id"
  add_foreign_key "risk_assessments", "teams", column: "assessed_by_team_id"
  add_foreign_key "risk_assessments", "users", column: "added_by_user_id"
  add_foreign_key "tests", "investigations"
  add_foreign_key "tests", "products"
  add_foreign_key "users", "teams"
end
