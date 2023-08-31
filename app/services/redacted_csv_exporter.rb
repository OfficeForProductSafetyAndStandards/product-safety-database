require "csv"

class RedactedCsvExporter
  attr_accessor :clean_tables_and_attributes, :running_time

  def initialize
    @running_time = Time.zone.now.to_i
    @clean_tables_and_attributes = load_clean_attributes
  end

  def export_tables
    FileUtils.mkdir_p Rails.root.join("tmp/redacted/#{running_time}")
    clean_tables_and_attributes.each do |table, attributes|
      puts "Exporting #{table}..."
      export_table(table:, attributes:)
    end
  end

private

  def export_table(table:, attributes:)
    filename = Rails.root.join("tmp/redacted/#{running_time}/#{table}.csv")
    CSV.open(filename, "w") do |csv|
      csv << attributes

      ActiveRecord::Base.connection.execute("SELECT #{attributes.join(', ')} FROM #{table}").each do |row|
        csv << row.values
      end
    end
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
