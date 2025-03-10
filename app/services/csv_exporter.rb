require "csv"

class CsvExporter
  attr_accessor :started_at, :started_at_safe, :output_directory, :tables_and_attributes

  ATTRIBUTES_TO_EXPORT = {
    "activities" => %w[id added_by_user_id business_id correspondence_id created_at investigation_id investigation_product_id type updated_at],
    "businesses" => %w[id added_by_user_id company_number created_at legal_name trading_name updated_at online_marketplace_id],
    "collaborations" => %w[id added_by_user_id collaborator_id collaborator_type created_at investigation_id type updated_at],
    "complainants" => %w[id complainant_type created_at investigation_id updated_at],
    "contacts" => %w[id added_by_user_id business_id created_at updated_at],
    "corrective_actions" => %w[id action business_id created_at date_decided details duration geographic_scope geographic_scopes has_online_recall_information investigation_id investigation_product_id legislation measure_type online_recall_information other_action updated_at],
    "correspondences" => %w[id contact_method correspondence_date correspondent_type created_at investigation_id type updated_at],
    "investigation_businesses" => %w[id authorised_representative_choice business_id created_at investigation_id online_marketplace_id relationship updated_at],
    "investigation_products" => %w[id affected_units_status batch_number created_at customs_code investigation_closed_at investigation_id number_of_affected_units product_id updated_at],
    "investigations" => %w[id complainant_reference coronavirus_related created_at custom_risk_level date_closed date_received deleted_at deleted_by description hazard_description hazard_type is_closed is_from_overseas_regulator is_private non_compliant_reason notifying_country overseas_regulator_country pretty_id product_category received_type reported_reason risk_level risk_validated_at risk_validated_by type updated_at user_title state tasks_status corrective_action_not_taken_reason corrective_action_taken submitted_at],
    "locations" => %w[id added_by_user_id address_line_1 address_line_2 business_id city country county created_at name phone_number postal_code updated_at],
    "online_marketplaces" => %w[id approved_by_opss created_at name updated_at],
    "organisations" => %w[id created_at name updated_at],
    "products" => %w[id added_by_user_id authenticity barcode brand category country_of_origin created_at description has_markings markings name owning_team_id product_code retired_at subcategory updated_at webpage when_placed_on_market],
    "risk_assessed_products" => %w[id created_at investigation_product_id risk_assessment_id updated_at],
    "risk_assessments" => %w[id added_by_team_id added_by_user_id assessed_by_business_id assessed_by_other assessed_by_team_id assessed_on created_at custom_risk_level details investigation_id risk_level updated_at],
    "teams" => %w[id country created_at deleted_at name organisation_id updated_at regulator_name team_type ts_acronym ts_area ts_region],
    "tests" => %w[id created_at date details failure_details investigation_id investigation_product_id legislation result standards_product_was_tested_against tso_certificate_issue_date tso_certificate_reference_number type updated_at],
    "ucr_numbers" => %w[id created_at investigation_product_id number updated_at],
    "unexpected_events" => %w[id additional_info created_at date investigation_id investigation_product_id is_date_known severity severity_other type updated_at usage],
    "users" => %w[id created_at deleted_at deleted_by has_accepted_declaration has_been_sent_welcome_email has_viewed_introduction invited_at mobile_number_verified organisation_id team_id updated_at],
    "versions" => %w[id created_at event item_id item_type whodunnit entity_type entity_id]
  }.freeze

  def initialize
    now = Time.zone.now
    @started_at = now.iso8601
    @started_at_safe = now.strftime("%Y-%m-%dT%H%M%S%z")
    @output_directory = Rails.root.join("tmp/csv_export/#{@started_at_safe}")
    @tables_and_attributes = selected_tables_and_attributes
  end

  def export_tables
    FileUtils.mkdir_p(output_directory)

    tables_and_attributes.each do |table, attributes|
      export_table(table, attributes)
    end

    create_log_file
    self
  end

  def upload_export
    files = Dir.glob("#{output_directory}/*.csv")

    s3_client = Aws::S3::Client.new(
      region: Rails.configuration.redacted_export["region"],
      access_key_id: Rails.configuration.redacted_export["access_key_id"],
      secret_access_key: Rails.configuration.redacted_export["secret_access_key"]
    )

    files.each do |file|
      upload_to_s3(s3_client, file)
    end

    upload_log_to_s3(s3_client)

    CsvExport.create!(started_at:, location: "csv/#{started_at_safe}/")
  end

private

  def selected_tables_and_attributes
    all_active_record_tables_and_attributes.each_with_object({}) do |(table, attributes), result|
      if ATTRIBUTES_TO_EXPORT.key?(table)
        result[table] = attributes.select { |attribute| ATTRIBUTES_TO_EXPORT[table].include?(attribute.keys.first) }
      end
    end
  end

  def all_active_record_tables_and_attributes
    ActiveRecord::Base.connection.tables.index_with do |table|
      ActiveRecord::Base.connection.columns(table).map { |t| { t.name => t.type } }
    end
  end

  def export_table(table, attributes)
    filename = "#{output_directory}/#{table}.csv"
    attribute_keys = attributes.map(&:keys).flatten

    table_class = classify_table_name(table)
    return unless table_class

    CSV.open(filename, "w") do |csv|
      csv << attribute_keys
      export_records_in_batches(table_class, attribute_keys, csv)
    end
  end

  def classify_table_name(table)
    table.classify.gsub(/^Prism(.+)/, "Prism::\\1").gsub(/^ActiveStorage(.+)/, "ActiveStorage::\\1").gsub(/^Version$/, "PaperTrail::Version").constantize
  rescue NameError => e
    log_error("Error classifying table #{table}: #{e.message}")
    nil
  end

  def export_records_in_batches(table_class, attributes, csv, batch_size = 10_000)
    total_records = table_class.count
    total_batches = (total_records.to_f / batch_size).ceil
    seen_ids = {}

    (0...total_batches).each do |batch|
      offset = batch * batch_size

      begin
        records = table_class.order(:id).limit(batch_size).offset(offset).pluck(*attributes)

        records.each do |row|
          id = row[attributes.index("id")]
          if seen_ids[id]
            next
          end

          seen_ids[id] = true
          csv << row
        end
      rescue StandardError => e
        Rails.logger.error "Error exporting records for table #{table_class}, batch #{batch + 1}: #{e.message}"
      end
    end
  end

  def create_log_file
    filename = "#{output_directory}/log.json"
    s3_location = "csv/#{started_at_safe}/"

    table_data = tables_and_attributes.keys.map { |table| { table => tables_and_attributes[table].map(&:merge).reduce(&:merge) } }

    data = {
      export_date: started_at,
      export_location: s3_location,
      tables: table_data.reduce(&:merge)
    }.to_json

    File.write(filename, data)
  end

  def upload_to_s3(s3_client, file)
    s3_client.put_object(
      bucket: Rails.configuration.redacted_export["destination_bucket"],
      key: "csv/#{started_at_safe}/#{File.basename(file)}",
      content_type: "text/csv",
      body: File.read(file)
    )
  end

  def upload_log_to_s3(s3_client)
    s3_client.put_object(
      bucket: Rails.configuration.redacted_export["destination_bucket"],
      key: "csv/#{started_at_safe}/log.json",
      content_type: "text/json",
      body: File.read("#{output_directory}/log.json")
    )
  end

  def log_error(message)
    Rails.logger.error message
  end
end
