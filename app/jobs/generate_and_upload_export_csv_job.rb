class GenerateAndUploadExportCsvJob < ApplicationJob
  def perform
    CsvExporter.new.export_tables.upload_export
  end
end
