class MigrateDocumentsToDocumentUploadsForProducts < ActiveRecord::Migration[7.0]
  def up
    attachments = ActiveStorage::Attachment.where(record_type: "Product")

    Rails.logger.debug "Migrating #{attachments.count} attachments..."

    attachments.each do |attachment|
      ActiveRecord::Base.transaction do
        Rails.logger.debug "Migrating attachment id=#{attachment.id}"
        # Create a new document upload and populate with details from the Active Storage attachment
        document_upload = DocumentUpload.new(
          upload_model: attachment.record,
          metadata: {
            title: attachment.blob.metadata["title"],
            description: attachment.blob.metadata["description"],
            created_by: attachment.blob.metadata["created_by"]
          },
          created_at: attachment.created_at,
          updated_at: attachment.blob.metadata["updated"] || attachment.created_at
        )
        document_upload.save!(validate: false) # The document upload won't be valid until we add the attachment
        # Attach the existing blob to the document upload
        document_upload.file_upload.attach(attachment.blob)
        # Remove redundant metadata from the blob
        document_upload.file_upload.blob.update!(
          metadata: attachment.blob.metadata&.except("title", "description", "created_by", "updated")
        )
        # Update the product to add the new document upload
        attachment.record.update!(
          document_upload_ids: (attachment.record.document_upload_ids << document_upload.id)
        )
        # Delete the old attachment
        attachment.delete
        Rails.logger.debug "Migrated attachment id=#{attachment.id}"
      end
    end
  end

  def down
    attachments = ActiveStorage::Attachment.where(record_type: "DocumentUpload")

    Rails.logger.debug "Migrating #{attachments.count} attachments..."

    attachments.each do |attachment|
      ActiveRecord::Base.transaction do
        Rails.logger.debug "Migrating attachment id=#{attachment.id}"
        document_upload = attachment.record
        # Add back the metadata to the blob
        attachment.blob.update!(
          metadata: {
            "title" => document_upload.metadata["title"],
            "description" => document_upload.metadata["description"],
            "created_by" => document_upload.metadata["created_by"],
            "updated" => document_upload.updated_at
          }.merge(attachment.blob.metadata),
        )
        # Update the Active Storage attachment to point to the product
        document_upload.upload_model.documents.attach(attachment.blob)
        # Delete the document upload and old attachment
        document_upload.delete
        attachment.delete
        Rails.logger.debug "Migrated attachment id=#{attachment.id}"
      end

      # Remove all document upload IDs
      Product.all.update!(document_upload_ids: [])
    end
  end
end
