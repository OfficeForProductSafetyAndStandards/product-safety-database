require "redacted_export"

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Base.include RedactedExport
end

# NOTE: Application models can define fields which will form part of a 'redacted' export:
#     redacted_export_with :id, :created_at, :updated_at
# NOTE: Rails internal or gem model fields added to the registry below.
#
# ActiveSupport.on_load(:active_storage) do
#   RedactedExport.register_model_attributes(
#     ActiveStorage::Attachment,
#     :id, :blob_id, :created_at, :name, :record_id, :record_type
#   )
#
#   RedactedExport.register_model_attributes(
#     ActiveStorage::Blob,
#     :id, :byte_size, :checksum, :content_type, :created_at, :filename, :service_name
#   )
#
#   RedactedExport.register_model_attributes(
#     ActiveStorage::VariantRecord,
#     :id, :blob_id
#   )
# end
