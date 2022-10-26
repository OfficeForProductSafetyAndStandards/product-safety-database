require "redacted_export"

Rails.application.config.redacted_export = Rails.application.config_for(:redacted_export)

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Base.include RedactedExport
end

# NOTE: Application models can define fields which will form part of a 'redacted' export:
#     redacted_export_with :id, :created_at, :updated_at

# NOTE: Rails internal or gem model fields can be added to the registry like this:
# ActiveSupport.on_load(:active_storage) do
#   RedactedExport.register_model_attributes(
#     ActiveStorage::Attachment,
#     :id, :blob_id, :created_at, :name, :record_id, :record_type
#   )
# end

# NOTE: Known or non-model tables can be redacted and exported like this:

RedactedExport.register_table_attributes(
  "active_storage_attachments",
  :id, :blob_id, :created_at, :name, :record_id, :record_type
)

RedactedExport.register_table_attributes(
  "active_storage_blobs",
  :id, :byte_size, :checksum, :content_type, :created_at, :filename, :service_name
)

RedactedExport.register_table_attributes(
  "active_storage_variant_records",
  :id, :blob_id
)

RedactedExport.register_table_attributes(
  "versions",
  :created_at, :event, :item_id, :item_type, :object, :object_changes, :whodunnit
)
