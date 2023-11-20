require "csv"

class RedactedCsvExporter
  def initialize
    @running_time = Time.zone.now.to_i
    @clean_tables_and_attributes = load_clean_attributes
  end

  def export_tables
    directory = "tmp/redacted/#{running_time}"
    FileUtils.mkdir_p(Rails.root.join(directory))
    clean_tables_and_attributes.each do |table, attributes|
      export_table(table:, attributes:, directory:)
    end
    self
  end

  def upload_export
    directory = Rails.root.join("tmp/redacted/#{running_time}")
    files = Dir.glob("#{directory}/*.csv")
    s3_client = Aws::S3::Client.new(
      region: Rails.configuration.redacted_export["region"],
      access_key_id: Rails.configuration.redacted_export["access_key_id"],
      secret_access_key: Rails.configuration.redacted_export["secret_access_key"]
    )
    files.each do |file|
      s3_client.put_object(
        bucket: Rails.configuration.redacted_export["destination_bucket"],
        key: "csv/#{running_time}/#{File.basename(file)}",
        content_type: "text/csv",
        body: File.read(file)
      )
    end
  end

private

  attr_accessor :clean_tables_and_attributes, :running_time

  def export_table(table:, attributes:, directory:)
    filename = Rails.root.join("#{directory}/#{table}.csv")

    table_name = table.to_s.classify.constantize
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
  rescue NameError => e
    # Some tables are not ActiveRecord models (eg. schema migrations) so we can't use the
    # `table_name.to_s.classify.constantize` method to always get a legit model
    Rails.logger.error "Error exporting #{table}: #{e.message}"
  end

  def load_clean_attributes
    clean_attributes = all_active_record_tables_and_attributes
    redacted_export_data.each do |table, attributes|
      if attributes.present?
        clean_attributes[table] = attributes
      end
    end
    clean_attributes
  end

  def redacted_export_data
    Rails.application.eager_load!
    RedactedExport.registry.with_all_tables
  end

  def all_active_record_tables_and_attributes
    tables = {}
    ActiveRecord::Base.connection.tables.map do |table|
      tables[table] = ActiveRecord::Base.connection.columns(table).map(&:name).map(&:to_sym)
    end
    tables
  end
end
