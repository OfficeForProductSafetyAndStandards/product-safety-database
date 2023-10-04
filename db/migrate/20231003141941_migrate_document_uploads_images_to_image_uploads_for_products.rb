class MigrateDocumentUploadsImagesToImageUploadsForProducts < ActiveRecord::Migration[7.0]
  # NOTE: Opensearch should be re-indexed manually after running this.
  #
  def up
    attachments = ActiveStorage::Attachment.where(record_type: "DocumentUpload").includes(:blob, record: :upload_model)
    images = attachments.select { |attachment| attachment.content_type.start_with?("image") }

    Rails.logger.debug "Migrating #{images.count} images..."

    images.each do |image|
      Rails.logger.debug "Migrating image id=#{image.id}"

      document_upload = image.record

      # Create a new image upload and populate with details from the document upload
      image_upload = ImageUpload.new(
        upload_model: image.record.upload_model,
        created_by: image.record.created_by,
        created_at: image.record.created_at,
        updated_at: image.record.updated_at
      )
      image_upload.save!(validate: false, touch: false) # The image upload won't be valid until we add the attachment

      # Update the product to add the new image upload and remove the old document upload.
      # Do not trigger callbacks which would create a new version and re-index
      # Opensearch.
      image.record.upload_model.update_columns(
        image_upload_ids: (image.record.upload_model.image_upload_ids << image_upload.id),
        document_upload_ids: (image.record.upload_model.document_upload_ids - [document_upload.id])
      )

      # Attach the existing blob to the image upload
      image.update_columns(record_id: image_upload.id, record_type: "ImageUpload")

      # Delete the document upload
      document_upload.delete

      Rails.logger.debug "Migrated image id=#{image.id}"
    end
  end

  # NOTE: Opensearch should be re-indexed manually after running this.
  #
  def down
    attachments = ActiveStorage::Attachment.where(record_type: "ImageUpload").includes(:blob, record: :upload_model)

    Rails.logger.debug "Migrating #{attachments.count} images..."

    attachments.each do |attachment|
      Rails.logger.debug "Migrating image id=#{attachment.id}"

      image_upload = attachment.record

      # Create a new document upload and populate with details from the image upload
      document_upload = DocumentUpload.new(
        upload_model: attachment.record.upload_model,
        title: "",
        description: "",
        created_by: attachment.record.created_by,
        created_at: attachment.record.created_at,
        updated_at: attachment.record.updated_at
      )
      document_upload.save!(validate: false, touch: false) # The document upload won't be valid until we add the attachment

      # Update the product to add the new document upload and remove the old image upload.
      # Do not trigger callbacks which would create a new version and re-index
      # Opensearch.
      attachment.record.upload_model.update_columns(
        document_upload_ids: (image.record.upload_model.document_upload_ids << document_upload.id),
        image_upload_ids: (image.record.upload_model.image_upload_ids - [image_upload.id])
      )

      # Attach the existing blob to the document upload
      image.update_columns(record_id: document_upload.id, record_type: "DocumentUpload")

      # Delete the image upload
      image_upload.delete

      Rails.logger.debug "Migrated image id=#{attachment.id}"
    end
  end
end
