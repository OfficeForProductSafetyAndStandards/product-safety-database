require "redacted_export"

Rails.configuration.to_prepare do
  ActiveRecord::Base.include RedactedExport
end

# NOTE: Application models can define fields which will form part of a 'redacted' export:
#     redacted_export_with :id, :created_at, :updated_at
#   Rails internal or gem model fields are injected as below.

Rails.configuration.after_initialize do
  ActiveStorage::Attachment.send(
    :redacted_export_with,
    :id, :blob_id, :created_at, :name, :record_id, :record_type
  )
  ActiveStorage::Blob.send(
    :redacted_export_with,
    :id, :byte_size, :checksum, :content_type, :created_at, :filename, :service_name
  )
  ActiveStorage::VariantRecord.send(
    :redacted_export_with,
    :id, :blob_id
  )
end
