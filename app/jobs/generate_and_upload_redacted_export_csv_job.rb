class GenerateAndUploadRedactedExportCsvJob < ApplicationJob
  def perform
    RedactedCsvExporter.new.export_tables.upload_export
  end
end
