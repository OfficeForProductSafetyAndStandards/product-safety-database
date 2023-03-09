class MigrateDocumentsToDocumentUploadsForProducts < ActiveRecord::Migration[7.0]
  # NOTE: Opensearch should be re-indexed manually after running this.
  #
  def up
    attachments = ActiveStorage::Attachment.where(record_type: "Product").includes(:blob, :record)

    Rails.logger.debug "Migrating #{attachments.count} attachments..."

    attachments.each do |attachment|
      Rails.logger.debug "Migrating attachment id=#{attachment.id}"
      # Create a new document upload and populate with details from the Active Storage attachment
      document_upload = DocumentUpload.new(
        upload_model: attachment.record,
        title: attachment.blob.metadata["title"],
        description: attachment.blob.metadata["description"],
        created_by: attachment.blob.metadata["created_by"],
        created_at: attachment.created_at,
        updated_at: attachment.blob.metadata["updated"] || attachment.created_at
      )
      document_upload.save!(validate: false, touch: false) # The document upload won't be valid until we add the attachment

      # Update the product to add the new document upload.
      # Do not trigger callbacks which would create a new version and re-index
      # Opensearch.
      attachment.record.update_column(:document_upload_ids, (attachment.record.document_upload_ids << document_upload.id))
      # Attach the existing blob to the document upload
      attachment.update_columns(name: "file_upload", record_id: document_upload.id, record_type: "DocumentUpload")

      # Remove redundant metadata from the blob
      attachment.blob.update_column(:metadata, attachment.blob.metadata.except("title", "description", "created_by", "updated"))

      Rails.logger.debug "Migrated attachment id=#{attachment.id}"
    end
  end

  # NOTE: Opensearch should be re-indexed manually after running this.
  #
  def down
    attachments = ActiveStorage::Attachment.where(record_type: "DocumentUpload").includes(:blob, :record)

    Rails.logger.debug "Migrating #{attachments.count} attachments..."

    attachments.each do |attachment|
      Rails.logger.debug "Migrating attachment id=#{attachment.id}"

      document_upload = attachment.record

      # Update the Active Storage attachment to point to the product
      attachment.update_columns(name: "documents", record_id: document_upload.upload_model_id, record_type: document_upload.upload_model_type)

      # Add back the metadata to the blob
      attachment.blob.update_column(:metadata, {
        "title" => document_upload.title,
        "description" => document_upload.description,
        "created_by" => document_upload.created_by,
        "updated" => document_upload.updated_at
      }.merge(attachment.blob.metadata))

      Rails.logger.debug "Migrated attachment id=#{attachment.id}"
    end

    # Do not create a new version record or trigger Elasticsearch callbacks.
    Product.update_all(document_upload_ids: [])
    DocumentUpload.delete_all
  end
end
