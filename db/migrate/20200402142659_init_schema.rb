class InitSchema < ActiveRecord::Migration[5.2]
  def up
    safety_assured do
      # These are extensions that must be enabled in order to support this database
      enable_extension "pgcrypto"
      enable_extension "plpgsql"

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
        t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
      end

      create_table "activities", id: :serial, force: :cascade do |t|
        t.text "body"
        t.bigint "business_id"
        t.bigint "correspondence_id"
        t.datetime "created_at", null: false
        t.integer "investigation_id"
        t.bigint "product_id"
        t.string "title"
        t.string "type", default: "CommentActivity"
        t.datetime "updated_at", null: false
        t.index ["business_id"], name: "index_activities_on_business_id"
        t.index ["correspondence_id"], name: "index_activities_on_correspondence_id"
        t.index ["investigation_id"], name: "index_activities_on_investigation_id"
        t.index ["product_id"], name: "index_activities_on_product_id"
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
        t.integer "business_id"
        t.datetime "created_at", null: false
        t.date "date_decided"
        t.text "details"
        t.string "duration"
        t.string "geographic_scope"
        t.integer "investigation_id"
        t.string "legislation"
        t.string "measure_type"
        t.integer "product_id"
        t.text "summary"
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
        t.boolean "has_consumer_info", default: false, null: false
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
        t.uuid "assignable_id"
        t.string "assignable_type"
        t.string "complainant_reference"
        t.boolean "coronavirus_related", default: false
        t.datetime "created_at", null: false
        t.date "date_received"
        t.text "description"
        t.text "hazard_description"
        t.string "hazard_type"
        t.boolean "is_closed", default: false
        t.boolean "is_private", default: false, null: false
        t.text "non_compliant_reason"
        t.string "pretty_id"
        t.string "product_category"
        t.string "received_type"
        t.string "type", default: "Investigation::Allegation"
        t.datetime "updated_at", null: false
        t.string "user_title"
        t.index ["assignable_type", "assignable_id"], name: "index_investigations_on_assignable_type_and_assignable_id"
        t.index ["pretty_id"], name: "index_investigations_on_pretty_id"
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

      create_table "products", id: :serial, force: :cascade do |t|
        t.string "batch_number"
        t.string "category"
        t.string "country_of_origin"
        t.datetime "created_at", null: false
        t.text "description"
        t.string "name"
        t.string "product_code"
        t.string "product_type"
        t.datetime "updated_at", null: false
        t.string "webpage"
      end

      create_table "rapex_imports", id: :serial, force: :cascade do |t|
        t.datetime "created_at", null: false
        t.string "reference", null: false
        t.datetime "updated_at", null: false
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
        t.datetime "created_at", null: false
        t.string "name"
        t.uuid "organisation_id"
        t.string "team_recipient_email"
        t.datetime "updated_at", null: false
        t.index ["name"], name: "index_teams_on_name"
        t.index ["organisation_id"], name: "index_teams_on_organisation_id"
      end

      create_table "teams_users", force: :cascade do |t|
        t.datetime "created_at", null: false
        t.uuid "team_id"
        t.datetime "updated_at", null: false
        t.uuid "user_id"
        t.index ["team_id"], name: "index_teams_users_on_team_id"
        t.index ["user_id"], name: "index_teams_users_on_user_id"
      end

      create_table "tests", id: :serial, force: :cascade do |t|
        t.datetime "created_at", null: false
        t.date "date"
        t.text "details"
        t.integer "investigation_id"
        t.string "legislation"
        t.integer "product_id"
        t.string "result"
        t.string "type"
        t.datetime "updated_at", null: false
        t.index ["investigation_id"], name: "index_tests_on_investigation_id"
        t.index ["product_id"], name: "index_tests_on_product_id"
      end

      create_table "user_roles", force: :cascade do |t|
        t.datetime "created_at", null: false
        t.string "name", null: false
        t.datetime "updated_at", null: false
        t.uuid "user_id"
        t.index ["user_id", "name"], name: "index_user_roles_on_user_id_and_name", unique: true
        t.index ["user_id"], name: "index_user_roles_on_user_id"
      end

      create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
        t.boolean "account_activated", default: false
        t.datetime "created_at", null: false
        t.string "credential_type"
        t.datetime "current_sign_in_at"
        t.inet "current_sign_in_ip"
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
        t.datetime "invited_at"
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
        t.integer "sign_in_count", default: 0, null: false
        t.string "unlock_token"
        t.datetime "updated_at", null: false
        t.index ["account_activated"], name: "index_users_on_account_activated"
        t.index ["email"], name: "index_users_on_email"
        t.index ["encrypted_otp_secret_key"], name: "index_users_on_encrypted_otp_secret_key", unique: true
        t.index ["name"], name: "index_users_on_name"
        t.index ["organisation_id"], name: "index_users_on_organisation_id"
        t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
        t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
      end

      add_foreign_key "activities", "businesses"
      add_foreign_key "activities", "correspondences"
      add_foreign_key "activities", "investigations"
      add_foreign_key "activities", "products"
      add_foreign_key "alerts", "investigations"
      add_foreign_key "complainants", "investigations"
      add_foreign_key "corrective_actions", "businesses"
      add_foreign_key "corrective_actions", "investigations"
      add_foreign_key "corrective_actions", "products"
      add_foreign_key "correspondences", "investigations"
      add_foreign_key "locations", "businesses"
      add_foreign_key "tests", "investigations"
      add_foreign_key "tests", "products"
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "The initial migration is not revertable"
  end
end
