require "csv"

class CsvExporter
  def initialize
    now = Time.zone.now
    @started_at = now.strftime("%FT%T%:z")
    @started_at_safe = now.strftime("%FT%H%M%S%z")
    @output_directory = Rails.root.join("tmp/csv_export/#{@started_at_safe}")
    @tables_and_attributes = all_active_record_tables_and_attributes
    @clean_tables = []
  end

  def export_tables
    FileUtils.mkdir_p(output_directory)

    tables_and_attributes.each do |table, attributes|
      export_table(table:, attributes:)
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
      s3_client.put_object(
        bucket: Rails.configuration.redacted_export["destination_bucket"],
        key: "csv/#{started_at_safe}/#{File.basename(file)}",
        content_type: "text/csv",
        body: File.read(file)
      )
    end

    s3_client.put_object(
      bucket: Rails.configuration.redacted_export["destination_bucket"],
      key: "csv/#{started_at_safe}/log.json",
      content_type: "text/json",
      body: File.read("#{output_directory}/log.json")
    )

    CsvExport.create!(started_at:, location: "csv/#{started_at_safe}/")
  end

private

  attr_accessor :started_at, :started_at_safe, :output_directory, :tables_and_attributes, :clean_tables

  # Exclude sensitive attributes
  EXCLUDED_ATTRIBUTES = %w[
    encrypted_password
    reset_password_token
    invitation_token
    password_salt
    encrypted_otp_secret_key
    encrypted_otp_secret_key_iv
    encrypted_otp_secret_key_salt
    direct_otp
    unlock_token
  ].freeze

  def export_table(table:, attributes:)
    filename = "#{output_directory}/#{table}.csv"
    attributes = attributes.map(&:keys).flatten - EXCLUDED_ATTRIBUTES

    # Correctly classify PRISM model names
    table_name = table.classify.gsub(/^Prism(.+)/, "Prism::\\1").constantize
    batch_size = 10_000
    offset = 0

    CSV.open(filename, "w") do |csv|
      csv << attributes

      loop do
        records = table_name.limit(batch_size).offset(offset).pluck(*attributes)
        break if records.empty?

        records.each do |row|
          csv << row
        end

        offset += batch_size
      end
    end

    clean_tables << table
  rescue NameError => e
    # Some tables are not ActiveRecord models (eg. schema migrations) so we can't use the
    # `table_name.classify.constantize` method to always get a legit model
    Rails.logger.error "Error exporting #{table}: #{e.message}"
  end

  def create_log_file
    filename = "#{output_directory}/log.json"
    s3_location = "csv/#{started_at_safe}/"

    table_data = clean_tables.map do |table|
      {
        table => tables_and_attributes[table].inject(&:merge)
      }
    end

    data = {
      export_date: started_at,
      export_location: s3_location,
      tables: table_data.inject(&:merge)
    }.to_json

    File.write(filename, data)
  end

  def all_active_record_tables_and_attributes
    tables = {}
    ActiveRecord::Base.connection.tables.map do |table|
      tables[table] = ActiveRecord::Base.connection.columns(table).map do |t|
        { t.name => t.type }
      end
    end
    tables
  end
end
