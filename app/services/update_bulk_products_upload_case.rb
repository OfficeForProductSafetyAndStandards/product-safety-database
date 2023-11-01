class UpdateBulkProductsUploadCase
  include Interactor

  delegate :bulk_products_upload, :user_title, :complainant_reference, to: :context

  def call
    context.fail!(error: "No bulk products upload supplied") unless bulk_products_upload.is_a?(BulkProductsUpload)
    context.fail!(error: "No user title supplied") unless user_title.is_a?(String)

    bulk_products_upload.investigation.update!(user_title:, complainant_reference:)
  end
end
