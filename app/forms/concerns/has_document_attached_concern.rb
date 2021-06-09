module HasDocumentAttachedConcern
  extend ActiveSupport::Concern

  def load_document_file
    if existing_document_file_id.present? && document.nil?
      self.document = ActiveStorage::Blob.find_signed!(existing_document_file_id)
      self.filename = document.filename.to_s
      self.file_description = document.metadata["description"]
    end
  end

  def assign_file_related_fields(file, description)
    file.rewind
    self.filename = file.original_filename
    self.file_description = description
    self.document = ActiveStorage::Blob.create_and_upload!(
      io: file,
      filename: file.original_filename,
      content_type: file.content_type,
      metadata: { description: file_description }
    )

    self.existing_document_file_id = document.signed_id
  end

  def assign_file_and_description(document_params)
    if document_params.key?(:file)
      assign_file_related_fields(*document_params.values_at(:file, :description))
    else
      load_document_file
      return if document.nil?

      self.file_description = document_params[:description]
      document.metadata[:description] = file_description
      document.save!
      document.reload
    end
  end
end
