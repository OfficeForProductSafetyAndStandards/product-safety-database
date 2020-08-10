module ActiveStorageAttachmentExtension
  def title
    blob.metadata["title"] if blob.present?
  end

  def description
    blob.metadata["description"] if blob.present?
  end

  def filename
    blob&.filename
  end
end

Rails.configuration.to_prepare do
  ActiveStorage::Attachment.include ::ActiveStorageAttachmentExtension
end
