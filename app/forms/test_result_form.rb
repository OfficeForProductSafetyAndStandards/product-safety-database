class TestResultForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :date, :govuk_date
  attribute :details
  attribute :legislation
  attribute :result
  attribute :standard_product_was_tested_against, :comma_separated_list
  attribute :product_id
  attribute :document, :file_field
  attribute :existing_document_file_id

  def cache_file!
    return if document.blank?

    blob = ActiveStorage::Blob.create_after_upload!(
      io: document.file,
      filename: document.original_filename,
      content_type: document.content_type
    )

    self.existing_document_file_id = blob.signed_id
  end

  def load_document_file
    if existing_document_file_id.present? && document.nil?
      self.document = ActiveStorage::Blob.find_signed(existing_document_file_id)
    end
  end
end
