namespace :redacted_export_csv do
  desc "Generate redacted exports as CSV files and upload to AWS S3"
  task generate_and_upload: %i[environment] do
    puts "Exporting tables..."
    export_tables = RedactedCsvExporter.new.export_tables

    puts "Uploading exported tables to AWS S3..."
    export_tables.upload_export
  end
end
