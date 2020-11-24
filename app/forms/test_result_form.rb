class TestResultForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :date, :govuk_date
  attribute :details
  attribute :legislation
  attribute :result
  attribute :standard_product_was_tested_against, :comma_separated_list
  attribute :product_id
  attribute :documents
  attribute :existing_documents_ids, default: []

  def cache_files!
    documents.each.with_object([]) do |document, blobs|
      blob = ActiveStorage::Blob.create_after_upload!(
        io: document,
        filename: document.original_filename,
        content_type: document.content_type
      )
      blobs.insert(documents.index(document), blob)

      existing_documents_ids << blob.signed_id
    end
  end
end
