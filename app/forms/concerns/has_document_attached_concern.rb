module HasDocumentAttachedConcern
  extend ActiveSupport::Concern

  def load_document_file
    if existing_document_file_id.present? && document.nil?
      self.document = ActiveStorage::Blob.find_signed!(existing_document_file_id)
      self.filename = document.filename.to_s
      self.file_description = document.metadata["description"]
    end
  end
end
